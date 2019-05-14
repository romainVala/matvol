function res=nifti_reg_measure(fflo,ffref,par)



 for k=1:length(ffref)
     cc=sprintf('reg_measure -ref %s -flo %s -ncc -nmi',ffref{k},fflo{k});
     [a b]=unix(cc);
     bb = strsplit(b);
     if  strfind(b,'No act')
         ncc(k) = NaN;nmi(k) = NaN;
     else
         ncc(k) = str2num(bb{2}) ;nmi(k) = str2num(bb{4});
     end
 end

res = [ncc; nmi];

 

