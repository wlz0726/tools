mkdir 04.f3f4.out
for i in 500
do
  echo "/home/wanglizhong/software/treemix/treemix-1.12/src/threepop -i treemix.input.gz -k $i > 04.f3f4.out/04.1.f3.win$i "
  echo "/home/wanglizhong/software/treemix/treemix-1.12/src/fourpop -i treemix.input.gz  -k $i > 04.f3f4.out/04.2.f4.win$i ";
done

