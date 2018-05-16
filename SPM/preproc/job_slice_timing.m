function jobs = job_slice_timing(fin,par)


if ~exist('par')
    par='';
end

defpar.TR   =0;
defpar.prefix = 'a';
defpar.sge = 0;
defpar.slice_order = 'interleaved_ascending';
defpar.file_reg = '^f.*nii';
defpar.reference_slice='middel'; 

defpar.jobname='spm_sliceTime';
defpar.walltime = '04:00:00';
defpar.run = 0;
defpar.display=0;
defpar.redo=0;
par = complet_struct(par,defpar);

TR = par.TR;


if iscell(fin{1})
    nsuj = length(fin);
else
    nsuj=1
end
skip=[];
for ns=1:nsuj
    
    if iscell(fin{1}) % 
        ff = get_subdir_regex_files(fin{ns},par.file_reg);
        unzip_volume(ff);
        ff = get_subdir_regex_files(fin{ns},par.file_reg);
        
    else
        ff = fin;        
    end
    
    for n=1:length(ff)
        ffsession = cellstr(ff{n}) ;
        
        if length(ffsession) == 1 %4D file
            V = spm_vol(ffsession{1});
            for k=1:length(V)
                ffs{k} = sprintf('%s,%d',ffsession{1},k);
            end
        else 
            ffs = ffsession;
        end
        jobs{ns}.spm.temporal.st.scans{n} = ffs';
    end
    
    %skip if last one exist
    of = addprefixtofilenames(ffsession(end),par.prefix);
    if ~par.redo
        if exist(of{1}),                skip = [skip ns];     fprintf('skiping subj %d because %s exist\n',ns,of{1});       end
    end
    
    
    V = spm_vol(ff{1}(1,:));
    nbslices = V(1).dim(3);
    TA = TR - (TR/nbslices);
    
    parameters.slicetiming.slice_order = par.slice_order;
    parameters.slicetiming.reference_slice = par.reference_slice;
    
    [slice_order,ref_slice] = get_slice_order(parameters,nbslices);
    
    
    jobs{ns}.spm.temporal.st.nslices = nbslices;
    jobs{ns}.spm.temporal.st.tr = TR;
    jobs{ns}.spm.temporal.st.ta = TA;
    
    jobs{ns}.spm.temporal.st.so = slice_order;
    jobs{ns}.spm.temporal.st.refslice = ref_slice;
    jobs{ns}.spm.temporal.st.prefix = 'a';
    
end

jobs(skip)=[];
if isempty(jobs), return;end

if par.sge
    for k=1:length(jobs)
        j=jobs(k);        
        cmd = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end

if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end

if par.run
    spm_jobman('run',jobs)
end

