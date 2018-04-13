function ants_warpANTS(fmov,fref,par)
%parameter from log of buildtemplate

if ~exist('par','var'),par ='';end


defpar.sge=1;
defpar.jobname = 'antsNLANTS';
defpar.walltime = '12:00:00';
defpar.prefix = 'aw_';
defpar.mask = '';
defpar.method = 's'; %   r: rigid        a: rigid + affine        s: rigid + affine + deformable syn
                     %    b: rigid + affine + deformable b-spline syn
defpar.histo = 0;
defpar.nb_thread = 1;
defpar.write_norm = 1;

par = complet_struct(par,defpar);

if length(fref)==1
    fref = repmat(fref,size(fmov));
end



[ppmov fname_mov ] = get_parent_path(fmov); fname_mov = change_file_extension(fname_mov,'');
[pp fname_ref ] = get_parent_path(fref); fname_ref = change_file_extension(fname_ref,'');


for k=1:length(fmov)
    
    transform = fullfile(ppmov{k},sprintf('%s%s_to_%s',par.prefix,fname_mov{k},fname_ref{k}));
        
    cmd = sprintf('ANTS 3 -m CC[%s,%s,1,5] -t SyN[0.25] -r Gauss[3,0] -o %s -i 30x90x20 --use-Histogram-Matching --number-of-affine-iterations 10000x10000x10000x10000x10000 --MI-option 32x16000',...
        fref{k},fmov{k},transform);
    
    if par.write_norm
        
        fo = addprefixtofilenames(fmov(k),'aw_');
        cmd = sprintf('%s\n WarpImageMultiTransform 3 %s %s -R %s %sWarp.nii.gz %sAffine.txt ',...
            cmd,fmov{k},fo{1},fref{k},transform,transform);
        
    end
    
    %cmd = sprintf('%s -n %d',cmd,par.nb_thread);
%     if par.histo
%         cmd = sprintf('%s -j 1',cmd);
%     end

    job{k} = cmd;
end

do_cmd_sge(job,par)