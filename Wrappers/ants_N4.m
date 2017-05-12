function [fo job] = ants_N4(fin,par,jobappend)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil

if ~exist('par','var'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.sge=1;
defpar.jobname = 'antsN4';
defpar.walltime = '01:00:00';
defpar.prefix = 'n4_';
defpar.mask = '';

defpar.nb_thread = 1;
defpar.save_bias = 1;

par = complet_struct(par,defpar);

fin = cellstr(char(fin));
fo = addprefixtofilenames(fin,par.prefix);
fob = addprefixtofilenames(fin,'bias_');

for k=1:length(fin)
    %test for tiwi     
    %cmd{k} =sprintf('N4BiasFieldCorrection -i %s -s 1 -c [50x50x50x50] -b [100] -o %s',fin{k},fo{k});
    %default from build template

    cmdi = sprintf(' export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=%d\n',par.nb_thread);

    cmd{k} =sprintf('%sN4BiasFieldCorrection -d 3 -i %s -b [200] -s 2 -c [50x50x30x20,1e-6]  ',cmdi,fin{k});
    %cmd{k} =sprintf('%sN4BiasFieldCorrection -d 3 -i %s -b [150] -s 2 -c [200x200,0.0]  ',cmdi,fin{k});
    %ni l'un ni l'autre ne marche sur les B0
    
    % mrtrix B0 bias field 
    %'N4BiasFieldCorrection -d 3 -i mean_bzero.nii -w mask.nii -o [corrected.nii,' + bias_path + '] -s 2 -b [150] -c [200x200,0.0]')
    if par.save_bias
        cmd{k} = sprintf('%s -o [%s,%s]',cmd{k},fo{k},fob{k});
    else
        cmd{k} = sprintf('%s -o %s',cmd{k},fo{k});
    end
    
    if ~isempty(par.mask)
        cmd{k} = sprintf('%s -x %s',cmd{k},par.mask{k});
    end 
    cmd{k} = sprintf('%s\n',cmd{k});
end


job = do_cmd_sge(cmd,par,jobappend);

