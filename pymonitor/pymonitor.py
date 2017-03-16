#!/opt/blc/python-2.6.5/bin/python

"""
Task submit and monitor system for SGE environment
Created by Li Miao
Version 1.0.1 (20140225)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import os
import sys
import time
import random
import re
import ConfigParser
from optparse import OptionParser
import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEImage import MIMEImage
#from email.mime.multipart import MIMEMultipart
#from email.mime.text import MIMEText
#from email.mime.image import MIMEImage
import socket
import io
import gzip
import drmaa
import ZODB
from ZODB import FileStorage, DB
import persistent
from persistent import Persistent
import transaction
from BTrees.OOBTree import OOBTree
import logging

handler = logging.FileHandler(os.environ['PYMONITOR_LOG_PATH'])
logging.getLogger('ZODB.FileStorage').addHandler(handler)
logging.getLogger('zc.lockfile').addHandler(handler)

#Classes
class configFile(object):
	"""This class is used to read/write the config file, including default parameters and project database information."""
	def __init__(self):
		self.cf = ConfigParser.SafeConfigParser()
		self.File = os.path.expanduser(os.environ['PYMONITOR_CONF_PATH'])
		needupdate = 0
		if not os.path.exists(self.File):
			self.cf.add_section('project')
			needupdate = 1
		else:
			self.cf.read(self.File)
			if (not self.cf.has_option('base', 'configVersion')) or (self.cf.getint('base', "configVersion") < 7):
				needupdate = 1
			if not self.cf.has_section('project'):
				self.cf.add_section('project')
				needupdate = 1
		if needupdate:
			#default value
			if not self.cf.has_section('base'):
				self.cf.add_section('base')
			self.cf.set('base', 'configVersion', '7')
			if not self.cf.has_option('base', 'defaultP'):
				self.cf.set('base', 'defaultP', 'tumortest')
			if not self.cf.has_option('base', 'defaultq'):
				self.cf.set('base', 'defaultq', 'bc.q')
			if not self.cf.has_option('base', 'defaultemail'):
				self.cf.set('base', 'defaultemail', '')
			if not self.cf.has_option('base', 'defaultemailmode'):
				self.cf.set('base', 'defaultemailmode', '2')
			if not self.cf.has_option('base', 'defaultMemG'):
				self.cf.set('base', 'defaultMemG', '4')
			if not self.cf.has_option('base', 'JobCheckInterval'):
				self.cf.set('base', 'JobCheckInterval', '10')
			if not self.cf.has_option('base', 'JobMaxRetries'):
				self.cf.set('base', 'JobMaxRetries', '5')
			#check resource every 3 times
			if not self.cf.has_option('base', 'ResCheckInterval'):
				self.cf.set('base', 'ResCheckInterval', '2')
			#suspend in 2 times(20*3*2 minutes)
			if not self.cf.has_option('base', 'SuspendInterval'):
				self.cf.set('base', 'SuspendInterval', '1')
			#FIXME: WH cluster temp patch
			if not self.cf.has_option('base', 'CpuTimeRatio'):
				self.cf.set('base', 'CpuTimeRatio', '0.001')
			if not self.cf.has_option('base', 'MemoryExceedLimit'):
				self.cf.set('base', 'MemoryExceedLimit', '1.5')
			if not self.cf.has_option('base', 'DiskMinSpaceG'):
				self.cf.set('base', 'DiskMinSpaceG', '500')
			if not self.cf.has_option('base', 'GlobalMaxJobs'):
				self.cf.set('base', 'GlobalMaxJobs', '600')
			if not self.cf.has_option('base', 'defaultFinishMark'):
				self.cf.set('base', 'defaultFinishMark', 'Still_waters_run_deep')
			if not self.cf.has_option('base', 'CronNode'):
				self.cf.set('base', 'CronNode', '')
			self.Update()
	def getHandle(self):
		return self.cf
	def Update(self):
		cfgfile = open(self.File, 'w')
		self.cf.write(cfgfile)
		cfgfile.close()
	def addPrj(self, prjname, prjdb):
		lockfilename = prjdb + '.lock'
		if not os.path.exists(lockfilename):
			reallockfilename = self.File + '.lock.' + prjname
			if not os.path.exists(reallockfilename):
				open(reallockfilename, 'a').close()
			os.symlink(reallockfilename, lockfilename)
		if len(self.cf.options('project')) == 0:
			cronobj = cronList()
			cronobj.addCron()
		self.cf.set('project', prjname, prjdb)
		self.Update()
	def removePrj(self, prjname):
		prjdb = self.cf.get('project', prjname)
		if os.path.exists(prjdb):
			os.remove(prjdb)
			os.remove(prjdb + ".index")
			lockfilename = prjdb + ".lock"
			try:
				reallockfilename = os.readlink(lockfilename)
				os.remove(reallockfilename)
			except:
				pass
			finally:
				os.remove(lockfilename)
			os.remove(prjdb + ".tmp")
		if os.path.exists(prjdb + ".old"):
			os.remove(prjdb + ".old")
		self.cf.remove_option('project', prjname)
		self.Update()
		if len(self.cf.options('project')) == 0:
			cronobj = cronList()
			cronobj.removeCron()

class ZDatabase(object):
	"""This is a wrapper for ZODB interface."""
	def Init(self, filename):
		try:
			self.storage = FileStorage.FileStorage(filename)
		except:
			return 0
		else:
			self.db = DB(self.storage)
			return 1
	def Open(self):
		self.conn = self.db.open()
		return self.conn.root()
	def Close(self):
		transaction.commit()
		self.conn.close()
	def Clean(self):
		self.db.pack()
	def Uninit(self):
		self.storage.close()

class cronList(object):
	"""This class is used to modify the cron list."""
	def __init__(self):
		self.program = os.environ['PYMONITOR_SH_PATH']
	def addCron(self):
		oldnode = ConfigFileObj.getHandle().get('base', 'CronNode')
		curnode = socket.gethostname()
		if oldnode and oldnode != curnode:
			print 'Warning: You have monitor jobs on node %s . If you want to work on current node, please use "%s cron -m 5" to change.' % (oldnode, self.program)
			return
		elif not oldnode:
			ConfigFileObj.getHandle().set('base', 'CronNode', curnode)
			ConfigFileObj.Update()
		pipe = os.popen('crontab -l', 'r')
		crontable = pipe.readlines()
		pipe.close()
		needcron=1
		for line in crontable:
			if line.find('monitor') > 0:
				needcron=0
		if needcron:
			#run cron job per 20 minutes
			interval = ConfigFileObj.getHandle().getint('base', 'JobCheckInterval')
			minute=random.randint(0, interval - 1)
			line = str(minute) + '-59/' + str(interval) + " * * * * " + self.program + " cron -m 1" + "\n"
			crontable.append(line)
			#run maintance job in 02:00-02:59
			minute=random.randint(0, 59)
			line = str(minute) + " 2 * * * " + self.program + " cron -m 2" + "\n"
			crontable.append(line)
			pipe = os.popen('crontab', 'w')
			for line in crontable:
				pipe.write(line)
			pipe.flush()
			pipe.close()
	def removeCron(self):
		oldnode = ConfigFileObj.getHandle().get('base', 'CronNode')
		curnode = socket.gethostname()
		if oldnode == curnode:
			ConfigFileObj.getHandle().set('base', 'CronNode', '')
			ConfigFileObj.Update()
		pipe = os.popen('crontab -l', 'r')
		crontable = pipe.readlines()
		pipe.close()
		if crontable:
			pipe = os.popen('crontab', 'w')
			for line in crontable:
				if line.find('monitor') == -1:
					pipe.write(line)
			pipe.flush()
			pipe.close()
	def checkCron(self):
		oldnode = ConfigFileObj.getHandle().get('base', 'CronNode')
		curnode = socket.gethostname()
		if oldnode and oldnode != curnode:
			sys.stderr.write("Warning: You have monitor jobs on node %s, but current node is %s. Removing cronjob now...\n" % (oldnode, curnode))
			self.removeCron()
			return 1
		else:
			return 0
	def changeCron(self):
		curnode = socket.gethostname()
		ConfigFileObj.getHandle().set('base', 'CronNode', curnode)
		ConfigFileObj.Update()
		self.addCron()
		
class projectClass(Persistent):
	"""This class represents the project database."""
	projectName = ''
	param_P = ''
	param_q = ''
	maxJobs = 0
	currentJobs = 0
	finishMark = ''
	allFinished = 0
	DiskWarning = 0
	submitEnabled = 1
	def __init__(self, ZODBroot):
		self.zroot = ZODBroot
		self.zroot['jobs'] = OOBTree()
		self.zroot['errorlog'] = persistent.list.PersistentList()
		#self.zroot['projectobj'] = self
	def ImportTaskmonitor(self, file, addmode):
		DrmaaSessionObj = drmaa.Session()
		DrmaaSessionObj.initialize()
		jobroot = self.zroot['jobs']
		list = open(file, 'r')
		lines = 0
		for line in list.readlines():
			lines = lines + 1
			if re.match(r'^\s+', line):
				print "The line of %s in your config.txt is invalid format, it cannot begin with null charcter or null line." %lines
				print "Please modify your config.txt format and remove your project by forced with '-b' and then resubmit."
				exit()
			joblist = line.strip().split()
			for jobstring in joblist:
				jobarray = jobstring.split(':')
				if not jobroot.has_key(jobarray[0]):
					#New job, assign property.
					jobroot[jobarray[0]] = jobClass(self)
					jobroot[jobarray[0]].FileName = jobarray[0]
					if len(jobarray) == 1:
						jobroot[jobarray[0]].memRequestedG = ConfigFileObj.getHandle().getint('base', 'defaultMemG')
					else:
						#get memory limit
						pmatch = re.search(r'([\d\.]+)(\w)', jobarray[1])
						if pmatch:
							if pmatch.group(2).upper() == 'G':
								jobroot[jobarray[0]].memRequestedG = float(pmatch.group(1))
							elif pmatch.group(2).upper() == 'M':
								jobroot[jobarray[0]].memRequestedG = float(pmatch.group(1)) / 1000
						#set job -q parameter.
						pmatch_q1 = re.match(r'(.*).q', jobarray[1])
						if pmatch_q1:
							jobroot[jobarray[0]].param_q = jobarray[1]
							jobroot[jobarray[0]].memRequestedG = ConfigFileObj.getHandle().getint('base', 'defaultMemG')
						if len(jobarray) ==3:
							pmatch_q2 = re.match(r'(.*).q', jobarray[2])
							if pmatch_q2:
								jobroot[jobarray[0]].param_q = jobarray[2]
				#check privous running information.
				jobpath = os.path.dirname(jobarray[0])
				jobscript = os.path.basename(jobarray[0])
				#use the latest (largest in number) jobid.
				jobid = ''
				for scriptfile in os.listdir(jobpath):
					pmatch = re.match(r'{0}.e(\d+)'.format(jobscript), scriptfile)
					if pmatch and (not jobid or int(jobid) < int(pmatch.group(1))):
						jobid = pmatch.group(1)
				# deal with existing job.
				jobroot[jobarray[0]].jobid = jobid
				jobroot[jobarray[0]].Status = ''
				jobroot[jobarray[0]].RetriedTimes = 0
				if addmode == 2:
					jobroot[jobarray[0]].RemoveLog(DrmaaSessionObj)
			firstjobname = joblist[0].split(':')[0]
			#The appending mode
			if addmode  == 1:
				if jobroot[firstjobname].jobid:
					logfile = jobroot[firstjobname].FileName + ".e" + str(jobroot[firstjobname].jobid)
					if os.path.exists(logfile):
						if os.path.getmtime(logfile) < os.path.getmtime(jobroot[firstjobname].FileName):
							jobroot[firstjobname].RemoveLog(DrmaaSessionObj)
					else:
						jobroot[firstjobname].RemoveLog(DrmaaSessionObj)
			#Reset all dependency.
			if len(joblist) > 1:
				secondjobname = joblist[1].split(':')[0]
				jobroot[secondjobname].Dependent[firstjobname] = 0
		list.close()
		DrmaaSessionObj.exit()
	def ImportQsubsge(self, file, addmode, linesep, resource):
		pmatch = re.search(r'vf=([\d\.]+)(\w)', resource)
		if pmatch:
			if pmatch.group(2).upper() == 'G':
				memRequestedG = float(pmatch.group(1))
			elif pmatch.group(2).upper() == 'M':
				memRequestedG = float(pmatch.group(1)) / 1000
		else:
			memRequestedG = ConfigFileObj.getHandle().getint('base', 'defaultMemG')
		jobroot = self.zroot['jobs']
		#privously added job.
                jobprevlist = []
                for jobprevname in jobroot.keys():
                        jobprevlist.append(jobprevname)
		scriptcounter = len(jobprevlist) + 1
		#directory
		jobpath = os.path.abspath(os.path.dirname(file))
		jobscript = os.path.basename(file)
		scriptdir = ''
		for dirname in os.listdir(jobpath):
			if re.match(r'{0}\.\d+\.qsub'.format(jobscript), dirname):
				newdir = jobpath + "/" + dirname
				if os.path.isdir(newdir):
					scriptdir = newdir
					break
		#addmode=1, remove old scripts.
		if scriptdir and addmode == 1:
			for scriptfile in os.listdir(scriptdir):
				scriptfile = scriptdir + "/" + scriptfile
				os.remove(scriptfile)
			os.removedirs(scriptdir)
			scriptdir = ''
		elif scriptdir and addmode == 0:
			for file in os.listdir(scriptdir):
				pmatch = re.match(r'(\S+)\.sh$', file)
				if pmatch:
					#first pass: find every shell script and add/reset them.
					filename = scriptdir + "/" + file
					if not jobroot.has_key(filename):
						jobroot[filename] = jobClass(self)
						jobroot[filename].FileName = filename
						jobroot[filename].memRequestedG = memRequestedG
					else:
						jobroot[filename].RetriedTimes = 0
						jobroot[filename].Status = ''
				else:
					#second pass: find .e file and add the jobid.
					pmatch = re.match(r'(\S+)\.e(\d+)$', file)
					if pmatch:
						scriptfile = scriptdir + "/" + pmatch.group(1)
						if jobroot.has_key(scriptfile):
							jobroot[scriptfile].jobid = pmatch.group(2)
		if not scriptdir:
			scriptdir = jobpath + "/" + jobscript + "." + str(os.getpid()) + ".qsub"
			os.mkdir(scriptdir)
			#add job object.
			list = open(file, 'r')
			linecounter = 0
			for line in list.readlines():
				if linecounter == 0:
					filename = scriptdir + "/" + jobscript + "_" + str(scriptcounter) + ".sh"
					jobroot[filename] = jobClass(self)
					jobroot[filename].FileName = filename
					jobroot[filename].memRequestedG = memRequestedG
					if addmode == 3:
						#previous dependency
						for prevjob in jobprevlist:
							jobroot[filename].Dependent[prevjob] = 0
					script = open(filename, 'w')	
				script.write(line)
				linecounter = linecounter + 1
				if linecounter >= linesep:
					linecounter = 0
					script.close()
					scriptcounter = scriptcounter + 1
			list.close()
	def Update(self, NoCounter):
		if self.allFinished:
			return
		self.checkDiskSpace()
		if self.DiskWarning == 1:
			self.SuspendProject()
			return
		elif self.DiskWarning == 2:
			self.ResumeProject()
			return
		elif self.DiskWarning == 3:
			return
		self.getStat(NoCounter)
		#manually override.
		if self.submitEnabled:
			self.submitNew()
	def checkDiskSpace(self):
		vfs = os.statvfs(os.path.dirname(ConfigFileObj.getHandle().get('project', self.projectName)))
		DiskSpaceG = vfs.f_bavail * vfs.f_frsize / (1024 * 1024 * 1024)
		if DiskSpaceG < ConfigFileObj.getHandle().getint('base', 'DiskMinSpaceG'):
			if self.DiskWarning == 3:
				pass
			elif self.DiskWarning == 1:
				self.DiskWarning = 3
			else:
				self.DiskWarning = 1
				self.writeLog('','',"disk_space_low")
		elif self.DiskWarning == 1 or self.DiskWarning == 3:
			self.DiskWarning = 2
			self.writeLog('','',"disk_space_normal")
		elif self.DiskWarning == 2:
			self.DiskWarning = 0
	def getStat(self, NoCounter):
		DrmaaSessionObj = drmaa.Session()
		DrmaaSessionObj.initialize()
		self.currentJobs = 0
		finishedJobs = 0
		jobroot = self.zroot['jobs']
		joblist = jobroot.keys()
		#update job status.
		for jobname in joblist:
			job = jobroot[jobname]
			if job.jobid:
				if job.Status != drmaa.JobState.DONE and job.Status != drmaa.JobState.FAILED:
					job.UpdateStatus(DrmaaSessionObj, NoCounter)
					self.currentJobs = self.currentJobs + 1
				elif job.Status == drmaa.JobState.DONE:
					finishedJobs = finishedJobs + 1
		#Update job dependency status. 
		for jobname in joblist:
			job = jobroot[jobname]
			for jobname in job.Dependent.keys():
				if jobroot[jobname].Status == drmaa.JobState.DONE:
					job.Dependent[jobname] = 1
				#FIXME: disable hold function now.
				elif jobroot[jobname].Status == drmaa.JobState.RUNNING:
				#	job.Dependent[jobname] = 2
					job.Dependent[jobname] = 0
				else:
					job.Dependent[jobname] = 0
					#if the privous job did't run or not successful, current job is meaningless.
					if job.jobid:
						job.RemoveLog(DrmaaSessionObj)
						finishedJobs = finishedJobs - 1
		#resubmit
		for jobname in joblist:
			job = jobroot[jobname]
			if job.jobid and job.Status == drmaa.JobState.FAILED and job.RetriedTimes < ConfigFileObj.getHandle().getint('base', 'JobMaxRetries'):
				job.RetriedTimes = job.RetriedTimes + 1
				job.RemoveLog(DrmaaSessionObj)
		if finishedJobs == len(joblist):
			self.allFinished = 1
			self.writeLog('','',"all_finished")
		DrmaaSessionObj.exit()
	def submitNew(self):
		DrmaaSessionObj = drmaa.Session()
		DrmaaSessionObj.initialize()
		jobroot = self.zroot['jobs']
		joblist = jobroot.keys()
		#check dependency and submit qualified jobs.
		for jobname in joblist:
			job = jobroot[jobname]
			if not job.jobid:
				finished = 1
				hold_jid = []
				for (jobname, jobstat) in job.Dependent.items():
					#if the dependency is still running, put it to hold list.
					if jobstat == 2:
						hold_jid.append(jobroot[jobname].jobid)
					finished = finished * jobstat
				if finished:
					if len(hold_jid):
						job.Parameter = ' -hold_jid ' + ','.join(hold_jid) + ' '
					if self.currentJobs < self.maxJobs:
						self.currentJobs = self.currentJobs + 1
						job.Submit(DrmaaSessionObj)		
		DrmaaSessionObj.exit()
	def SuspendProject(self):
		self.getStat(1)
		DrmaaSessionObj = drmaa.Session()
		DrmaaSessionObj.initialize()
		jobroot = self.zroot['jobs']
		joblist = jobroot.keys()
		for jobname in joblist:
			job = jobroot[jobname]
			if job.Status == drmaa.JobState.RUNNING:
				job.Control(DrmaaSessionObj, drmaa.JobControlAction.SUSPEND)
			elif job.Status == drmaa.JobState.QUEUED_ACTIVE:
				job.Control(DrmaaSessionObj, drmaa.JobControlAction.HOLD)
		DrmaaSessionObj.exit()
	def ResumeProject(self):
		DrmaaSessionObj = drmaa.Session()
		DrmaaSessionObj.initialize()
		jobroot = self.zroot['jobs']
		joblist = jobroot.keys()
		for jobname in joblist:
			job = jobroot[jobname]
			if job.Status == drmaa.JobState.USER_SUSPENDED:
				job.Control(DrmaaSessionObj, drmaa.JobControlAction.RESUME)
			elif job.Status == drmaa.JobState.USER_ON_HOLD or job.Status == drmaa.JobState.USER_SYSTEM_ON_HOLD:
				job.Control(DrmaaSessionObj, drmaa.JobControlAction.RELEASE)
		DrmaaSessionObj.exit()
	def DeleteProject(self):
		#this function delete job from sge queue, but don't delete .e and .o files.
		self.getStat(1)
		DrmaaSessionObj = drmaa.Session()
		DrmaaSessionObj.initialize()
		jobroot = self.zroot['jobs']
		joblist = jobroot.keys()
		for jobname in joblist:
			job = jobroot[jobname]
			if job.jobid and (job.Status != drmaa.JobState.DONE and job.Status != drmaa.JobState.FAILED):
				job.Control(DrmaaSessionObj, drmaa.JobControlAction.TERMINATE)
		DrmaaSessionObj.exit()
	def clearErrorState(self):
		#clear error counter.
		jobroot = self.zroot['jobs']
		joblist = jobroot.keys()
		for jobname in joblist:
			job = jobroot[jobname]
			if job.jobid and job.Status == drmaa.JobState.FAILED:
				job.RetriedTimes = 0
	def writeLog(self, jobname, jobid, logstring):
		timestr = time.strftime('%Y-%m-%d %H:%M:%S')
		logstr = timestr + " " + jobname + " " + jobid + " " + logstring
		self.zroot['errorlog'].append(logstr)
	def clearLog(self):
		del self.zroot['errorlog']
		self.zroot['errorlog'] = persistent.list.PersistentList()
		self.writeLog('','',"log_cleared")
		
class jobClass(Persistent):
	"""This class represents a single job."""
	#jobid: unsubmitted = ''; submitted = jobid; submitted but unknown = 'unknown'
	jobid = ''
	FileName = ''
	Parameter = ''
	memRequestedG = 0
	param_q = ''
	#status was updated in each Update. Empty means it never got updated.
	Status = ''
	cpuUsage = ''
	memUsageG = 0
	#counter for checking resource status.
	ResCheckCounter = 0
	#counter for determine if the suspend status got too long(node dead).
	SuspendCounter = 0
	RetriedTimes = 0
	def __init__(self, project):
		#Dependent: name status
		#status: 0 not started; 1 finished; 2 running but not finished.
		self.Dependent = persistent.mapping.PersistentMapping()
		self.projectObj = project
	def UpdateStatus(self, DrmaaSessionObj, NoCounter):
		if self.jobid == 'unknown':
			if not self.FindLostJob():
				self.Status = drmaa.JobState.FAILED
				return
		#status check
		self.checkFinishStatus(DrmaaSessionObj)
		if NoCounter:
			return
		#suspend check.
		if self.Status == drmaa.JobState.SYSTEM_SUSPENDED:
			self.SuspendCounter = self.SuspendCounter + 1
		#resource check
		elif self.Status == drmaa.JobState.RUNNING:
			if self.ResCheckCounter > ConfigFileObj.getHandle().getint('base', 'ResCheckInterval'):
				if self.checkResStatus():
					#normal: clear counter
					self.SuspendCounter = 0
				else:
					#dead: increase counter
					self.SuspendCounter = self.SuspendCounter + 1
				#check res status every 3 times by clear the counter.
				self.ResCheckCounter = 0
			else:
				self.ResCheckCounter = self.ResCheckCounter + 1
		if self.SuspendCounter > ConfigFileObj.getHandle().getint('base', 'SuspendInterval'):
			self.Status = drmaa.JobState.FAILED
			self.projectObj.writeLog(self.FileName, self.jobid, "node_dead")
	def Submit(self, DrmaaSessionObj):
		jt = DrmaaSessionObj.createJobTemplate()
		jt.remoteCommand = self.FileName
		jt.workingDirectory = os.path.dirname(self.FileName)
		if self.param_q:
			self.projectObj.param_q = self.param_q
		elif optlist.opt_q:
			self.projectObj.param_q = optlist.opt_q
		else:
			self.projectObj.param_q = "bc.q"
		jt.nativeSpecification = "-b no -shell yes -l vf=" + str(self.memRequestedG) + "G" + " -P " + self.projectObj.param_P + " -q " + self.projectObj.param_q + " " + self.Parameter
		#FIXME: prevent repeat submit
		previd = 0
		jobscript = os.path.basename(self.FileName)
		for scriptfile in os.listdir(jt.workingDirectory):
			pmatch = re.match(r'{0}.e(\d+)'.format(jobscript), scriptfile)
			if pmatch and int(previd) < int(pmatch.group(1)):
				previd = pmatch.group(1)
		if previd:
			self.jobid = previd
			self.projectObj.writeLog(self.FileName, self.jobid, "found")
		else:
			#remove error handler. Error means SGE is malfunction, thus further operation is meaningless.
			self.jobid = DrmaaSessionObj.runJob(jt)
		
		if not self.jobid:
			self.jobid = 'unknown'
		self.projectObj.writeLog(self.FileName, self.jobid, "submitted")
		DrmaaSessionObj.deleteJobTemplate(jt)
	def checkResStatus(self):
		command = "qstat -j " + str(self.jobid) + " | grep usage"
		pipe = os.popen(command, 'r')
		line = pipe.read()
		pipe.close()
		pmatch = re.search(r'cpu=([\d:]+),.*vmem=([\d\.]+)(\w)', line)
		ret = 1
		if pmatch:
			#cpu
			if self.cpuUsage == pmatch.group(1) or self.checkSlowCpu(pmatch.group(1)):
				self.Status = drmaa.JobState.SYSTEM_SUSPENDED
				self.projectObj.writeLog(self.FileName, self.jobid, "cpu_slow")
				ret = 0
			else:
				self.cpuUsage = pmatch.group(1)
			#mem
			if pmatch.group(3).upper() == 'G':
				self.memUsageG = float(pmatch.group(2))
			elif pmatch.group(3).upper() == 'M':
				self.memUsageG = float(pmatch.group(2)) / 1000
			if self.memUsageG / self.memRequestedG > ConfigFileObj.getHandle().getfloat('base', 'MemoryExceedLimit'):
				self.Status = drmaa.JobState.SYSTEM_SUSPENDED
				self.projectObj.writeLog(self.FileName, self.jobid, "memory_exceed_limit")
				ret = 0
		else:
			if line.find('cpu=00:00:00') > -1 or line.find('vmem=N/A') > -1:
				self.Status = drmaa.JobState.SYSTEM_SUSPENDED
				self.projectObj.writeLog(self.FileName, self.jobid, "node_unavailable")
				ret = 0
		return ret
	def checkFinishStatus(self, DrmaaSessionObj):
		finishMark = self.projectObj.finishMark
		if finishMark == '':
			self.Status = drmaa.JobState.DONE
			self.projectObj.writeLog(self.FileName, self.jobid, "finished")
		elif finishMark == '.sign':
			file = self.FileName + ".sign"
			if os.path.exists(file):
				self.Status = drmaa.JobState.DONE
				self.projectObj.writeLog(self.FileName, self.jobid, "finished")
			else:
				try:
					self.Status = DrmaaSessionObj.jobStatus(self.jobid)
				except drmaa.errors.InvalidJobException, exception:
					self.Status = drmaa.JobState.FAILED
					self.projectObj.writeLog(self.FileName, self.jobid, "job failed because SGE not feedback jobstat or not generate '.sign' file.")
		else:
			if finishMark.find('.o') == 0:
				file = self.FileName + ".o" + self.jobid
				finishMark = finishMark.split(":")[-1]
			else:
				file = self.FileName + ".e" + self.jobid
			if (not os.path.exists(file)) or (os.path.getsize(file) == 0):
				try:
					self.Status = DrmaaSessionObj.jobStatus(self.jobid)
				except drmaa.errors.InvalidJobException, exception:
					self.Status = drmaa.JobState.FAILED
					self.projectObj.writeLog(self.FileName, self.jobid, "job failed because SGE not feedback jobstat or not get result of '.e' file.")
			else:
				filehandle = open(file, 'r')
				filehandle.seek(0, os.SEEK_END)
				size = filehandle.tell()
				if size > 80:
					filehandle.seek(-80, os.SEEK_END)
				else:
					filehandle.seek(0, os.SEEK_SET)
				line = filehandle.readlines()[-1]
				filehandle.close()
				if line.find(finishMark) > -1:
					self.Status = drmaa.JobState.DONE
					self.projectObj.writeLog(self.FileName, self.jobid, "finished")
				else:
					try:
						self.Status = DrmaaSessionObj.jobStatus(self.jobid)
					except drmaa.errors.InvalidJobException, exception:
						self.Status = drmaa.JobState.FAILED
						self.projectObj.writeLog(self.FileName, self.jobid, "job failed because SGE feedback invalid jobstat.")
			
	def Control(self, DrmaaSessionObj, operation):
		#status was updated each time.
		try:
			DrmaaSessionObj.control(self.jobid, operation)
			self.Status = DrmaaSessionObj.jobStatus(self.jobid)
		except drmaa.errors.InvalidJobException, exception:
			self.checkFinishStatus(DrmaaSessionObj)
		self.projectObj.writeLog(self.FileName, self.jobid, self.Status)
	def RemoveLog(self, DrmaaSessionObj):
		#remove job and .e .o file. Reset it to init stat.
		try:
			DrmaaSessionObj.control(self.jobid, drmaa.JobControlAction.TERMINATE)
		except :
			pass
		self.projectObj.writeLog(self.FileName, self.jobid, "resetted")
		filename = self.FileName + ".e" + self.jobid
		if os.path.exists(filename):
			os.remove(filename)
			filename = self.FileName + ".o" + self.jobid
			os.remove(filename)
		filename = self.FileName + ".sign"
		if os.path.exists(filename):
			os.remove(filename)
		self.Status = ''
		self.jobid = ''
		self.ResCheckCounter = 0
		self.SuspendCounter = 0
		if self.memUsageG > self.memRequestedG:
			self.memRequestedG = self.memUsageG
		self.cpuUsage = ''
	def checkSlowCpu(self, CurrentTime):
		#convert cputime to seconds.
		if self.cpuUsage:
			timearray = self.cpuUsage.split(':')
			lasttime = int(timearray[-1]) + int(timearray[-2]) * 60 + int(timearray[-3]) * 60 * 60
			if len(timearray) > 3:
				lasttime = lasttime + int(timearray[0]) * 60 * 60 * 24
		else:
			lasttime = 0
		timearray = CurrentTime.split(':')
		currenttime = int(timearray[-1]) + int(timearray[-2]) * 60 + int(timearray[-3]) * 60 * 60
		if len(timearray) > 3:
			currenttime = currenttime + int(timearray[0]) * 60 * 60 * 24
		interval = currenttime - lasttime
		#standard time
		refinterval = ConfigFileObj.getHandle().getint('base', 'JobCheckInterval') * (ConfigFileObj.getHandle().getint('base', 'ResCheckInterval') + 1) * 60
		if float(interval) / float(refinterval) < ConfigFileObj.getHandle().getfloat('base', 'CpuTimeRatio'):
			#cpu is really slow.
			return 1
		else:
			return 0

	def FindLostJob(self):
		#check privous running information.
		jobpath = os.path.dirname(self.FileName)
		jobscript = os.path.basename(self.FileName)
		#use the latest (largest in number) jobid.
		jobid = ''
		for scriptfile in os.listdir(jobpath):
			pmatch = re.match(r'{0}.e(\d+)'.format(jobscript), scriptfile)
			if pmatch:
				if not jobid:
					jobid = pmatch.group(1)
				elif int(jobid) < int(pmatch.group(1)):
					jobid = pmatch.group(1)
		if jobid:
			self.jobid = jobid
			#did find job.
			self.projectObj.writeLog(self.FileName, self.jobid, "jobid_lost_and_found")
			return 1
		else:
			self.projectObj.writeLog(self.FileName, self.jobid, "jobid_lost")
			return 0

class directExec(object):
	"""This class controls the direct running function."""
	def progexec(self, file, binary, stream, p, q, resource):
		DrmaaSessionObj = drmaa.Session()
		DrmaaSessionObj.initialize()
		jt = DrmaaSessionObj.createJobTemplate()
		#command
		filearray = file.split()
		jt.remoteCommand = filearray[0]
		jt.args = filearray[1:]
		jt.workingDirectory = os.getcwd()
		#binary exec
		if binary:
			parameter = "-b yes"
		else:
			parameter = "-b no"
		prefix = jt.workingDirectory + "/" + os.path.basename(filearray[0])
		stdinfile = prefix + ".stdin"
		stdoutfile = prefix + ".stdout"
		stderrfile = prefix + ".stderr"
		#put stdin to file
		if stream:
			fh = open(stdinfile, 'w')
			fh.write(sys.stdin.read())
			fh.close()
			parameter = parameter + " -i " + stdinfile
		parameter = parameter + " -o " + stdoutfile + " -e " + stderrfile
		parameter = parameter + " -shell yes -l " + resource + " -P " + p + " -q " + q
		jt.nativeSpecification = parameter
		#run
		jobid = DrmaaSessionObj.runJob(jt)
		sys.stderr.write("%s submitted.\n" % jobid)
		try:
			retval = DrmaaSessionObj.wait(jobid, drmaa.Session.TIMEOUT_WAIT_FOREVER)
		except:
			sys.stderr.write("%s failed.\n" % jobid)
		sys.stderr.write("%s finished.\n" % jobid)
		DrmaaSessionObj.deleteJobTemplate(jt)
		DrmaaSessionObj.exit()
		#process input/output file.
		if os.path.exists(stdinfile):
			os.remove(stdinfile)
		if os.path.exists(stdoutfile):
			fh = open(stdoutfile, 'r')
			sys.stdout.write(fh.read())
			fh.close()
			os.remove(stdoutfile)
		if os.path.exists(stderrfile):
			fh = open(stderrfile, 'r')
			sys.stderr.write(fh.read())
			fh.close()
			os.remove(stderrfile)
		return retval.exitStatus

class Report:
	"""This class is used to generate status report, plot figure and send email."""
	def __init__(self):
		self.projectList = ConfigFileObj.getHandle().items('project')
	def getStatus(self, projectname):
		#get status summary of a project. 
		zodbobj = ZDatabase()
		location = ConfigFileObj.getHandle().get('project', projectname)
		if not zodbobj.Init(location):
			print "Cannot open " + location
			return
		zodbroot = zodbobj.Open()
		if len(zodbroot) == 0:
			print "Broken database " + location
			return
		statusList = {'pending':0, 'queued':0, 'paused':0, 'hold':0, 'suspend':0, 'running':0, 'finished':0, 'error':0}
		jobroot = zodbroot['jobs']
		joblist = jobroot.keys()
		for jobname in joblist:
			job = jobroot[jobname]
			if not job.jobid:
				statusList['pending'] = statusList['pending'] + 1
			elif (not job.Status) or (job.Status == drmaa.JobState.QUEUED_ACTIVE):
				statusList['queued'] = statusList['queued'] + 1
			elif job.Status == drmaa.JobState.USER_SUSPENDED or job.Status == drmaa.JobState.USER_ON_HOLD:
				statusList['paused'] = statusList['paused'] + 1
			elif job.Status == drmaa.JobState.SYSTEM_ON_HOLD:
				statusList['hold'] = statusList['hold'] + 1
			elif job.Status == drmaa.JobState.SYSTEM_SUSPENDED:
				statusList['suspend'] = statusList['suspend'] + 1
			elif job.Status == drmaa.JobState.RUNNING:
				statusList['running'] = statusList['running'] + 1
			elif job.Status == drmaa.JobState.DONE:
				statusList['finished'] = statusList['finished'] + 1
			elif job.Status == drmaa.JobState.FAILED:
				statusList['error'] = statusList['error'] + 1
		linearray = [zodbroot['projectobj'].projectName, str(statusList['pending']), str(statusList['queued']), str(statusList['paused']), str(statusList['hold']), str(statusList['suspend']), str(statusList['running']), str(statusList['finished']), str(statusList['error']), str(len(joblist)), str(zodbroot['projectobj'].maxJobs)]
		line = '\t'.join(linearray)
		zodbobj.Close()
		zodbobj.Uninit()
		return line
	def JobStat(self, projectname):
		#print each job in a project.
		zodbobj = ZDatabase()
		location = ConfigFileObj.getHandle().get('project', projectname)
		if not zodbobj.Init(location):
			print "Cannot open " + location
			return
		zodbroot = zodbobj.Open()
		if len(zodbroot) == 0:
			print "Broken database " + location
			return
		jobroot = zodbroot['jobs']
		joblist = jobroot.keys()
		for jobname in joblist:
			job = jobroot[jobname]
			if job.Status=='':
				if job.jobid:
					linearray = [job.FileName, job.jobid, "queued"]
				else:
					linearray = [job.FileName, job.jobid, "pending"]
			else:
				linearray = [job.FileName, job.jobid, job.Status]
			print "\t".join(linearray)
		zodbobj.Close()
		zodbobj.Uninit()
	def sendMail(self, receiver, mode, linebuffer):
		#send email. mode: 1.text summary; 2.figure
		sender = os.environ['USER'] + '@genomics.cn'
		if receiver.find('@') < 0:
			receiver = ConfigFileObj.getHandle().get('base', "defaultemail")
		if not receiver:
			print "Receiver not found."
			return
		msg = MIMEMultipart()
		msg['Subject'] = 'PyMonitor Status Report'
		msg['From'] = sender
		msg['To'] = receiver
		if mode == 1:
			messagebody='<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head><body><p>PyMonitor Status Report</p>\n<table border="1">\n'
			for line in linebuffer:
				messagebody = messagebody + '<tr>\n'
				linearray = line.split()
				for cell in linearray:
					messagebody = messagebody + '<td>' + cell + '</td>\n'
				messagebody = messagebody + '</tr>\n'
			messagebody = messagebody + '</table></body></html>\n'
			msgtxt = MIMEText(messagebody, 'html')
			msg.attach(msgtxt)
		elif mode == 2:
			messagebody = "Please use Chrome / Firefox / Safari / Opera / IE9 to open the attachment. If your browser can't recognize .svgz file, try unzipping it and rename to .svg .\nProject Status Figures:\n"
			messagebody = messagebody + "\n".join(linebuffer)
			msgtxt = MIMEText(messagebody)
			msg.attach(msgtxt)
			for file in linebuffer:
				if not os.path.exists(file): 
					continue
				fh = open(file, 'rb')
				if os.path.getsize(file) > 1000000:
					memio = io.BytesIO()
					gzipobj = gzip.GzipFile(mode='wb', fileobj=memio)
					gzipobj.writelines(fh)
					gzipobj.close()
					file = file + ".gz"
					msgimg = MIMEImage(memio.getvalue(), _subtype='svg+xml')
					memio.close()
				else:
					msgimg = MIMEImage(fh.read(), _subtype='svg+xml')
				fh.close()
				msgimg.add_header('Content-Disposition', 'inline', filename = os.path.basename(file))
				msg.attach(msgimg)
		self.sendmailhelper(msg.as_string())
	def sendmailhelper(self, message):
		p = os.popen("/usr/sbin/sendmail -oi -t", "w")
		p.write(message)
		p.close()
	def plotFigure(self, projectname):
		#use graphviz to plot status figure.
		decodestatus = {
		        drmaa.JobState.UNDETERMINED: 'white',
			drmaa.JobState.QUEUED_ACTIVE: 'lightgreen',
			drmaa.JobState.SYSTEM_ON_HOLD: 'lightskyblue',
			drmaa.JobState.USER_ON_HOLD: 'pink',
		        drmaa.JobState.USER_SYSTEM_ON_HOLD: 'pink',
		        drmaa.JobState.RUNNING: 'limegreen',
		        drmaa.JobState.SYSTEM_SUSPENDED: 'orange',
		        drmaa.JobState.USER_SUSPENDED: 'violet',
		        drmaa.JobState.DONE: 'darkgrey',
		        drmaa.JobState.FAILED: 'red',
		}
		zodbobj = ZDatabase()
		location = ConfigFileObj.getHandle().get('project', projectname)
		if not zodbobj.Init(location):
			print "Cannot open " + location
			return
		zodbroot = zodbobj.Open()
		if len(zodbroot) == 0:
			print "Broken database " + location
			return
		dotname = location + ".dot"
		svgname = location + ".svg"
		dotfile = open(dotname, 'w')
		dotfile.write("digraph G{\n")
		dotfile.write("rankdir = TB;\n")
		jobroot = zodbroot['jobs']
		joblist = jobroot.keys()
		for jobname in joblist:
			#node
			nodename = re.sub(r'[\/\-\.]', '_', jobname)
			nodelabel = os.path.basename(jobname)
			nodecolor = 'white'
			if jobroot[jobname].Status:
				nodecolor = decodestatus[jobroot[jobname].Status]
			elif jobroot[jobname].jobid:
				nodecolor = 'khaki'
			dotfile.write('%s [shape = box, label = "%s", color = "%s", style = filled];\n' % (nodename, nodelabel, nodecolor))
			#arrow
			for depjobname in jobroot[jobname].Dependent.keys():
				dependname = re.sub(r'[\/\-\.]', '_', depjobname)
				dotfile.write('%s -> %s\n' % (dependname, nodename))
		zodbobj.Close()
		zodbobj.Uninit()
		dotfile.write('}\n')
		dotfile.close()
		os.system('dot -Tsvg -o %s %s' % (svgname, dotname))
		os.remove(dotname)
		return svgname

#Functions
def usage():
	"""
	Task submit and monitor system for SGE environment.
	Created by Li Miao(limiao@genomics.cn). Version 1.0.1 (20140225)
	
	Usage:
		monitor <command> [arguments]
	
	Command should be one of the following command. Arguments depend on specific command.
	
	Command List:
		taskmonitor	Add a task_monitor.py format task list.
			Arguments:
			-i <FILE>	input config.txt file.
			-P <STR>  	-P argument for qsub.
			-q <STR>	-q argument for qsub.
			-n <INT>	maximum number of jobs.
			-p <STR>	project name for monitor.
			-f <INT>	Finish Mark.
				0	Using the strings specified by -s option at the end of .e files.
				1	Using .sign files.
				2	Don't check.
				3	Using the strings specified by -s option at the end of .o files.
			-s <STR>	Finish string for -f option.
			-m <INT>	Operation mode for resubmitting the same project.
				0	Resubmit those didn't successfully finished, and jobs depend on them.
				1	Resubmit scripts that were added or modified after execution, and jobs depend on them.
				2	Resubmit all jobs. No matter successful or not.

		qsubsge		Add a qsub_sge.pl format task list.
			Arguments:
			-i <FILE>	input work.sh file.
			-L <INT>	number of lines to form a job
			-P <STR>  	-P argument for qsub.
			-q <STR>	-q argument for qsub.
			-l <STR>	resource limitation.
			-n <INT>	maximum number of jobs.
			-p <STR>	project name for monitor.
			-f <INT>	Finish Mark.
				0	Using the strings specified by -s option at the end of .e files.
				1	Using .sign files.
				2	Don't check.
				3	Using the strings specified by -s option at the end of .o files.
			-s <STR>	Finish string for -f option.
			-m <INT>	Operation mode for submitting in the same project.
				0	Resubmit those didn't successfully finished, and jobs depend on them.
				1	Regenerate and resubmit all jobs. No matter successful or not.
				2	Submit new jobs parallel with the old jobs.
				3	Submit new jobs depend on the old jobs.
		
		directrun		Directly execute a program on compute node.
			Arguments:
			-i <FILE>	program to be executed. Must be quoted by ' '.
			-b		program is a binary executable file.
			-d		program reads from stdin stream. (for pipe)
			-P <STR>  	-P argument for qsub.
			-q <STR>	-q argument for qsub.
			-l <STR>	resource limitation.

		stat		List all project status monitored by this program.
			Arguments:
			-p <STR>	Project name. If not specify, show all projects.
			-m <INT>	Display mode:
				0	Show status of the project.
				1	Show figure of the project.
				2	Show name of all projects.
				3	Show job detail of the project.
			-e <STR>	email address. By specifing this arguments, the above information will be sent as email. (only support -m 0 and -m 1)
		
		setdefault	Set default value.
			-m <INT>	Daily email sending mode:
				0	Send text summary.
				1	Send figure summary.
				2	Do not send.
			-e <STR>	email address.
			-P <STR>  	-P argument for qsub.
			-q <STR>	-q argument for qsub.
			-n <INT>	Monitor running interval (minutes). This will also change monitor node to current node.
			-l <STR>	resource limitation.
			-L <INT>	Minimal disk free space(G).

		pauseproject	Pause jobs belong to the specified project.
			Arguments:
			-p <STR>	project name for monitor.
			-m <INT>	Operation mode:
				0	Waiting for current running jobs to complete, but don't submit new jobs in this project.
				1	Immediately put all jobs in this project to Hold state.

		resumeproject	Resume paused project.
			Arguments:
			-p <STR>	project name for monitor.

		removeproject	Remove a project. Removing a project will delete the monitor database and the project can not be resumed.
			Arguments:
			-p <STR>	project name for monitor.
			-m <INT>	Operation mode:
				0	Waiting for current running jobs to complete then remove the project.
				1	Immediately stop all jobs belonging to the project then remove the project.
			-d		Remove all finished projects.
			-b		Remove broken project database.

		updateproject	Update a project.
			Arguments:
			-p <STR>	project name for monitor.
			-b		Clear job error state.

		setmaxjobs	Set maxium number of jobs running in a project.
			Arguments:
			-p <STR>	project name for monitor.
			-n <INT>	Set maxium jobs running at the same time.

		logdump		Dump logs of a project.
			Arguments:
			-p <STR>	project name for monitor.
			-d		Delete logs from database.
		
		cron		Do cron job.
			Arguments:
			-m <INT>	Operation mode:
				0	Do nothing.
				1	Check job status.
				2	Database maintance.
				3	Add crontab.
				4	Delete crontab.
				5	Change monitor node to current node.

		help		Show this help.
	
	Document:
		The most recent document was placed in http://bgi.genomics.cn/my/personal/limiao/Shared%20Documents/Forms/AllItems.aspx
	"""
	print (usage.__doc__)
	exit(1)

def test():
	reportobj = Report()

def projectstat():
	#all function regarding status.
	reportobj = Report()
	if optlist.opt_m == 0:
		linebuffer = []
		linearray = ["Name", "Pending", "Queued", "Paused", "Hold", "Suspend", "Running", "Done", "Error", "Total", "Max"]
		linebuffer.append("\t".join(linearray))
		namelist = []
		if optlist.opt_p:
			namelist.append(optlist.opt_p)
		else:
			namelist = ConfigFileObj.getHandle().options('project')
		for name in namelist:
			line = reportobj.getStatus(name)
			if line:
				linebuffer.append(line)
		if optlist.opt_e:
			reportobj.sendMail(optlist.opt_e, 1, linebuffer)
		else:
			print '\n'.join(linebuffer)
	elif optlist.opt_m == 1:
		linebuffer = []
		namelist = []
		if optlist.opt_p:
			namelist.append(optlist.opt_p)
		else:
			namelist = ConfigFileObj.getHandle().options('project')
		for name in namelist:
			filename = reportobj.plotFigure(name)
			if filename:
				linebuffer.append(filename)
		if optlist.opt_e:
			reportobj.sendMail(optlist.opt_e, 2, linebuffer)
		else:
			print "The following figures were generated:"
			print '\n'.join(linebuffer)
	if optlist.opt_m == 2:
		linearray = ["Name", "Location"]
		print "\t".join(linearray)
		for (name, location) in ConfigFileObj.getHandle().items('project'):
			linearray = [name, location]
			print "\t".join(linearray)
	elif optlist.opt_m == 3:
		linearray = ["Name", "id", "Status"]
		print "\t".join(linearray)
		namelist = []
		if optlist.opt_p:
			namelist.append(optlist.opt_p)
		else:
			namelist = ConfigFileObj.getHandle().options('project')
		for name in namelist:
			reportobj.JobStat(name)
	
def projectaction():
	#all project operation.
	if not optlist.opt_p:
		print "project name must be supplied."
		return
	projectname = optlist.opt_p
	if ConfigFileObj.getHandle().has_option('project', projectname):
		location = ConfigFileObj.getHandle().get('project', projectname)
	else:
		print "Cannot open " + projectname 
		return
	zodbobj = ZDatabase()
	if not zodbobj.Init(location):
		print "Cannot open " + location
		return
	zodbroot = zodbobj.Open()
	if len(zodbroot) == 0:
		print "Broken database " + location
		return
	projectobj = zodbroot['projectobj']
	if 'pauseproject' in args:
		if optlist.opt_m == 0:
			projectobj.submitEnabled = 0
		elif optlist.opt_m == 1:
			projectobj.SuspendProject()
	elif 'resumeproject' in args:
		projectobj.ResumeProject()
		projectobj.submitEnabled = 1
	elif 'removeproject' in args:
		if optlist.opt_m == 1:
			projectobj.DeleteProject()
	elif 'updateproject' in args:
		if optlist.opt_b:
			projectobj.clearErrorState()
		projectobj.Update(1)
	elif 'setmaxjobs' in args:
		if optlist.opt_n:
			projectobj.maxJobs = optlist.opt_n
		else:
			maxjobs = ConfigFileObj.getHandle().getint('base', 'GlobalMaxJobs')
			jobnumber = len(ConfigFileObj.getHandle().options('project'))
			maxjobs = int(maxjobs / jobnumber)
			projectobj.maxJobs = maxjobs
	elif 'logdump' in args:
		for line in zodbroot['errorlog']:
			print line
		if optlist.opt_d:
			projectobj.clearLog()
	zodbobj.Close()
	zodbobj.Uninit()
	if 'removeproject' in args:
		ConfigFileObj.removePrj(projectname)
def projectimport():
	#all import projects.
	if not optlist.opt_p:
		print "project name must be supplied."
		return
	if re.search(r'\W', optlist.opt_p):
		print "Special character not allowed in project name."
		return
	if socket.gethostname().find('compute') > -1:
		print "This program should be executed on login node."
		return
	print "Creating database. This might take a while..."
	projectname = optlist.opt_p
	confighandle = ConfigFileObj.getHandle()
	if confighandle.has_option('project', projectname):
		print 'You have submit the project of "%s", did you want to add to "%s"? please input "Y" or "N":' %(projectname,projectname)
		Y_N = sys.stdin.readline()
		num = 0
		while(num < 100):
			if re.match('^Y$', Y_N, re.I):
				projectlocation = confighandle.get('project', projectname)
				break
			elif re.match('^N$', Y_N, re.I):
				print "Please change you project name and resubmit."
				exit()
			else:
				print "The character your input is invalid, please input 'Y' or 'N'."
				Y_N = sys.stdin.readline()
				num = num + 1
	else:
		projectlocation = os.getcwd() + "/" + projectname + ".db"
		ConfigFileObj.addPrj(projectname, projectlocation)
	zodbobj = ZDatabase()
	if not zodbobj.Init(projectlocation):
		print "Cannot open " + projectlocation
		return
	zodbroot = zodbobj.Open()
	if not zodbroot.has_key('projectobj'):
		zodbroot['projectobj'] = projectClass(zodbroot)
	projectobj = zodbroot['projectobj']
	projectobj.projectName = projectname
	projectobj.param_P = optlist.opt_P
	projectobj.param_q = optlist.opt_q
	projectobj.allFinished = 0
	if optlist.opt_n:
		projectobj.maxJobs = optlist.opt_n
	else:
		maxjobs = ConfigFileObj.getHandle().getint('base', 'GlobalMaxJobs')
		jobnumber = len(ConfigFileObj.getHandle().options('project'))
		maxjobs = int(maxjobs / jobnumber)
		projectobj.maxJobs = maxjobs
	finishmark = ConfigFileObj.getHandle().get('base', 'defaultFinishMark')
	if "taskmonitor" in args:
		if optlist.opt_f is None or optlist.opt_f == 0:
			if optlist.opt_s:
				finishmark = optlist.opt_s
		elif optlist.opt_f == 1:
			finishmark = ".sign"
		elif optlist.opt_f == 2:
			finishmark = ''
		elif optlist.opt_f == 3:
			finishmark = '.o:' + optlist.opt_s
		projectobj.finishMark = finishmark
		projectobj.ImportTaskmonitor(optlist.opt_i, optlist.opt_m)
	elif "qsubsge" in args:
		if optlist.opt_f == 0:
			if optlist.opt_s:
				finishmark = optlist.opt_s
		elif optlist.opt_f == 1:
			finishmark = ".sign"
		elif optlist.opt_f is None or optlist.opt_f == 2:
			finishmark = ''
		elif optlist.opt_f == 3:
			finishmark = '.o:' + optlist.opt_s
		projectobj.finishMark = finishmark
		projectobj.ImportQsubsge(optlist.opt_i, optlist.opt_m, optlist.opt_L, optlist.opt_l)
	projectobj.Update(1)
	zodbobj.Close()
	zodbobj.Uninit()
	print 'Successfully created project of "%s". Jobs will be submitted in a few minutes. Use "%s stat" to view project status.' % (projectname, os.environ['PYMONITOR_SH_PATH'])

def removefinishedprojects():
	projectlist = ConfigFileObj.getHandle().items('project')
	zodbobj = ZDatabase()
	for (name, location) in projectlist:
		needclean = 0
		if zodbobj.Init(location):
			zodbroot = zodbobj.Open()
			if len(zodbroot) == 0:
				needclean = 1
			else:
				projectobj = zodbroot['projectobj']
				needclean = projectobj.allFinished
			zodbobj.Close()
			zodbobj.Uninit()
		elif not os.path.exists(location):
			needclean = 1
		if needclean:
			ConfigFileObj.removePrj(name)

def removebrokenproject():
	if not optlist.opt_p:
		print "project name must be supplied."
		return
	projectname = optlist.opt_p
	ConfigFileObj.removePrj(projectname)

def cronjob():
	cronobj = cronList()
	if optlist.opt_m == 1:
		if cronobj.checkCron():
			return
		#update job status.
		projectlist = ConfigFileObj.getHandle().items('project')
		zodbobj = ZDatabase()
		for (name, location) in projectlist:
			if not zodbobj.Init(location):
				continue
			zodbroot = zodbobj.Open()
			if len(zodbroot) > 0:
				projectobj = zodbroot['projectobj']
				projectobj.Update(0)
			zodbobj.Close()
			zodbobj.Uninit()
	elif optlist.opt_m == 2:
		if cronobj.checkCron():
			return
		#submit email.
		emailmode =  ConfigFileObj.getHandle().getint('base', 'defaultemailmode')
		receiver = ConfigFileObj.getHandle().get('base', "defaultemail")
		if emailmode != 2 and receiver.find('@') > 0:
			optlist.opt_m = emailmode
			optlist.opt_e = receiver
			projectstat()
		#dbpack, removefinished
		projectlist = ConfigFileObj.getHandle().items('project')
		zodbobj = ZDatabase()
		for (name, location) in projectlist:
			if not zodbobj.Init(location):
				if not os.path.exists(location):
					ConfigFileObj.removePrj(name)
				continue
			zodbroot = zodbobj.Open()
			if len(zodbroot) == 0:
				zodbobj.Close()
				zodbobj.Uninit()
				ConfigFileObj.removePrj(name)
				continue
			projectobj = zodbroot['projectobj']
			if projectobj.allFinished < 2:
				filename = location + ".log"
				fh = open(filename, 'a')
				for line in zodbroot['errorlog']:
					fh.write(line + "\n")
				fh.close()
				projectobj.clearLog()
				if projectobj.allFinished == 1:
					projectobj.allFinished = 2
				zodbobj.Close()
				zodbobj.Clean()
				zodbobj.Uninit()
			elif projectobj.allFinished == 2:
				zodbobj.Close()
				zodbobj.Uninit()
				ConfigFileObj.removePrj(name)
	elif optlist.opt_m == 3:
		cronobj.addCron()
	elif optlist.opt_m == 4:
		cronobj.removeCron()
	elif optlist.opt_m == 5:
		cronobj.changeCron()

def directexec():
	if optlist.opt_l:
		resource = optlist.opt_l
	else:
		resource = "vf=" + ConfigFileObj.getHandle().get('base', 'defaultMemG') + "G"
	dirobj = directExec()
	ret = dirobj.progexec(optlist.opt_i, optlist.opt_b, optlist.opt_d, optlist.opt_P, optlist.opt_q, resource)
	exit(ret)

def setdefault():
	confighandle = ConfigFileObj.getHandle()
	if '-m' in sys.argv:
		confighandle.set('base', 'defaultemailmode', str(optlist.opt_m))
	if optlist.opt_e:
		confighandle.set('base', 'defaultemail', optlist.opt_e)
	if optlist.opt_P:
		confighandle.set('base', 'defaultP', optlist.opt_P)
	if optlist.opt_q:
		confighandle.set('base', 'defaultq', optlist.opt_q)
	if optlist.opt_n:
		confighandle.set('base', 'JobCheckInterval', str(optlist.opt_n))
	if optlist.opt_l:
		pmatch = re.search(r'vf=([\d\.]+)(\w)', optlist.opt_l)
		memRequestedG = 0
		if pmatch:
			if pmatch.group(2).upper() == 'G':
				memRequestedG = float(pmatch.group(1))
			elif pmatch.group(2).upper() == 'M':
				memRequestedG = float(pmatch.group(1)) / 1000
		if memRequestedG:
			confighandle.set('base', 'defaultMemG', str(memRequestedG))
	if optlist.opt_L and optlist.opt_L != 1:
		confighandle.set('base', 'DiskMinSpaceG', str(optlist.opt_L))
	ConfigFileObj.Update()
	if optlist.opt_n:
		cronobj = cronList()
		cronobj.removeCron()
		cronobj.changeCron()

if __name__=='__main__':
	if len(sys.argv) < 2:
		usage()
	
	#Common objects
	ConfigFileObj = configFile()
	confighandle = ConfigFileObj.getHandle()
	parser = OptionParser()
	parser.add_option("-p", dest = "opt_p", type = "string")
	parser.add_option("-m", dest = "opt_m", type = "int", default = 0)
	parser.add_option("-q", dest = "opt_q", type = "string", default = confighandle.get('base', 'defaultq'))
	parser.add_option("-P", dest = "opt_P", type = "string", default = confighandle.get('base', 'defaultP'))
	parser.add_option("-f", dest = "opt_f", type = "int")
	parser.add_option("-s", dest = "opt_s", type = "string")
	parser.add_option("-i", dest = "opt_i", type = "string")
	parser.add_option("-L", dest = "opt_L", type = "int", default = 1)
	parser.add_option("-n", dest = "opt_n", type = "int")
	parser.add_option("-e", dest = "opt_e", type = "string")
	parser.add_option("-l", dest = "opt_l", type = "string")
	parser.add_option("-b", dest = "opt_b", action="store_true", default= False)
	parser.add_option("-d", dest = "opt_d", action="store_true", default= False)
	(optlist, args) = parser.parse_args()
	
	#Main function
	if 'help' in  args:
		usage()
	elif 'test' in args:
		test()
	elif 'taskmonitor' in args:
		projectimport()
	elif 'qsubsge' in args:
		projectimport()
	elif 'pauseproject' in args:
		projectaction()
	elif 'resumeproject' in args:
		projectaction()
	elif 'updateproject' in args:
		projectaction()
	elif 'removeproject' in args:
		if optlist.opt_d:
			removefinishedprojects()
		elif optlist.opt_b:
			removebrokenproject()
		else:
			projectaction()
	elif 'directrun' in args:
		directexec()
	elif 'setmaxjobs' in args:
		projectaction()
	elif 'logdump' in args:
		projectaction()
	elif 'setdefault' in args:
		setdefault()
	elif 'stat' in args:
		projectstat()
	elif 'cron' in args:
		cronjob()
	else:
		usage()

