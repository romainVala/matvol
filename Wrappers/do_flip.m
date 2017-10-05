function do_flip(fin,fo)

fin=cellstr(char(fin));
fo=cellstr(char(fo));

if  ~exist('fo','var')
    fo= addprefixtofilenames(fin,'flip_');
end


for n=1:length(fin)
    clear v
    [v A]=nifti_spm_vol(fin{n});
    
    B=A(:,:,v(1).dim(3):-1:1,:);
   
    %try and test shift of y translation ...
    %dsize=abs(v(1).mat*[v(1).dim 1]' -v(1).mat*[0 0 0 1]' )
    %v(1).mat(2,4)=v(1).mat(2,4)+dsize(2);
    dsize=-v(1).mat*[v(1).dim 1]'
    %34.1560 34.6642
    %keyboard
    for k=1:length(v)
        v(k).mat(2,4)=v(k).mat(2,4)+dsize(2); %/2 pour la dti et pas /2 pour l'anat, ... n'importe quoi !
        v(k).fname=fo{n};
        spm_write_vol(v(k),B(:,:,:,k));
    end
end
