function [output, nofiledir, yesfiledir]  = get_subdir_regex_files4D(indir,reg_ex,p)


if ~exist('p'), p=struct;end
if ~exist('indir'), indir={pwd};end
if ~exist('reg_ex'), reg_ex=('graphically');end

[output, nofiledir, yesfiledir]  = get_subdir_regex_files(indir,reg_ex,p);


for nbf = 1:length(output)
    ff = cellstr(output{nbf});
    
    ntot = 1;            
    for nn = 1:length(ff)
        V = nifti_spm_vol(ff{nn});
        
        for nbv=1:length(V)
            oo{ntot} = sprintf('%s,%d',ff{nn},nbv);
            ntot=ntot+1;
        end                
    end
    
    if isfield(p,'skip_vol')
        oo(p.skip_vol)='';
    end
        
    OUT{nbf,1} = char(oo);
    
end

output=OUT;

end

