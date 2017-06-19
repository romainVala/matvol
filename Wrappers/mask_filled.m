function fo = mask_filled(fin,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par','var'),par ='';end

defpar.suffix = '_filled';
defpar.jobname='mask_filled'
defpar.walltime = '01:00:00';
defpar.sge=0;

par = complet_struct(par,defpar);

fo = addsuffixtofilenames(fin,par.suffix);

for nbf=1:length(fin)
    
    [pp ff ] = fileparts(fin{nbf});
    
    cmd = sprintf('cd %s',pp);
    cmd = sprintf('%s\nfslsplit %s split -x',cmd,fin{nbf});
    cmd = sprintf('%s\nfor i in `ls split*`; do c3d  $i -pad 1x0x0vox 1x0x0vox 1 -o toto.nii.gz; c3d toto.nii.gz -holefill 1 0 -o toto.nii.gz; fslsplit toto.nii.gz sss -x; mv -f sss0001.nii.gz $i; done',cmd);
    cmd = sprintf('%s\n fslmerge -x totoX split*',cmd);
    
    cmd = sprintf('%s\n rm -f sss* split* toto.nii*',cmd);
    
    cmd = sprintf('%s\nfslsplit totoX split -y',cmd);
    cmd = sprintf('%s\nfor i in `ls split*`; do c3d  $i -pad 0x1x0vox 0x1x0vox 1 -o toto.nii.gz; c3d toto.nii.gz -holefill 1 0 -o toto.nii.gz; fslsplit toto.nii.gz sss -y; mv -f sss0001.nii.gz $i; done',cmd);
    cmd = sprintf('%s\nfslmerge -y totoX split*',cmd);

    cmd = sprintf('%s\n rm -f sss* split* toto.nii*',cmd);
    
    cmd = sprintf('%s\nfslsplit totoX split -z',cmd);
    cmd = sprintf('%s\nfor i in `ls split*`; do c3d  $i -pad 0x0x1vox 0x0x1vox 1 -o toto.nii.gz; c3d toto.nii.gz -holefill 1 0 -o toto.nii.gz; fslsplit toto.nii.gz sss -z; mv -f sss0001.nii.gz $i; done',cmd);
    cmd = sprintf('%s\nfslmerge -z %s split*',cmd,fo{nbf});

    cmd = sprintf('%s\n rm -f sss* split* toto.nii* totoX.nii*',cmd);
    
    %for bug in xdim3 with c3d -pad in z dir
    cmd = sprintf('%s\n fslcpgeom %s %s',cmd,fin{nbf},fo{nbf});
    
 
CC{nbf} = cmd;    
end
do_cmd_sge(CC,par);
