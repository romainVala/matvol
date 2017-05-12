function do_minc_normalize(vol,ref,transfo)

if ~exist('vol')
  vol = spm_select(inf,'.*','select vol to normalize','',pwd);vol= cellstr(vol);
end

if ~exist('ref')
  ref = spm_select(inf,'.*','select reference','',pwd);ref= cellstr(ref);
end

if ~exist('transfo')
  transfo = spm_select(inf,'.*xfm$','select transfo','',pwd);transfo= cellstr(transfo);
end

par.prefix = 'mimc_';

for nbsuj = 1:length(ref)

  [ppref,volrefname,ex2] = fileparts(ref{nbsuj});
  if strcmp(ex2,'.gz')
    aa2 = unzip_volume(ref{nbsuj}) 
    [ppref,volrefname,ex2] = fileparts(aa2{1});
  end
  
  thevol = cellstr(char(vol{nbsuj}));
  
  for nbvol = 1:length(thevol)
    [outdir,volname,ex1] = fileparts(thevol{nbvol});
    
    if strcmp(ex1,'.gz')
        aa1 = unzip_volume(thevol{nbvol}) 
	[outdir,volname,ex1] = fileparts(aa1{1});
    end

    [pp, transfoname] = fileparts(transfo{nbsuj});
  
    CMD = sprintf('cd %s;\n',outdir);

    if strcmp(ex2,'.img')
      ex2='.hdr';
    end

    if strcmp(ex1,'.img')
      ex1='.hdr';
    end

    CMD = sprintf('%snii2mnc %s vol1.mnc;\n',CMD,[volname ex1]);

    if nbvol==1
      CMD = sprintf('%snii2mnc %s volref.mnc;\n',CMD,fullfile(ppref,[volrefname,ex2]))
    end      
    
    CMD = sprintf('%smincresample -like volref.mnc -transformation %s vol1.mnc vol2.mnc  -clobber;\n',CMD,transfo{nbsuj});
    %CMD = sprintf('%smnc2nii vol2.mnc %s.nii\n',CMD,[par.prefix,transfoname,'_',volname])
  
    unix(CMD)
    
    if exist('aa2'),       gzip_volume(aa2);clear aa2;     end
    if exist('aa1'),       gzip_volume(aa1);clear aa1;     end
  
    cd(outdir);
if 0  
    job{1}.spm.util.minc.data = {'vol2.mnc'};
    job{1}.spm.util.minc.opts.dtype = 4;
    job{1}.spm.util.minc.opts.ext = '.nii';
    spm_jobman('run',job)
    
    CMD = sprintf('mv -f vol2.nii %s.nii',[par.prefix,transfoname,'_',volname]);
  
    unix(CMD);
else
   CMD = sprintf('mri_convert  vol2.mnc %s.nii',[par.prefix,transfoname,'_',volname]);
   unix(CMD)
end

    CMD = sprintf('rm -f vol1.mnc vol2.mnc')
    unix(CMD)
  
  end
  
  CMD = sprintf('rm -f volref.mnc ')
  unix(CMD)
  
end
