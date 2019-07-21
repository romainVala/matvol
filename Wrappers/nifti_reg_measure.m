function res=nifti_reg_measure(fflo,ffref,par)


count=0;
 for k=1:length(ffref)
     for kf=1:size(fflo{k},1) >1
         count=count+1;
         ffflo = deblank( ffl{k}(kf,:) );
         cc=sprintf('reg_measure -ref %s -flo %s -ncc -nmi',ffref{k},ffflo);
         [a b]=unix(cc);
         bb = strsplit(b);
         if  strfind(b,'No act')
             ncc(count) = NaN;nmi(count) = NaN;
         else
             ncc(count) = str2num(bb{2}) ;nmi(count) = str2num(bb{4});
         end
     end
     
 end

res = [ncc; nmi];

 

