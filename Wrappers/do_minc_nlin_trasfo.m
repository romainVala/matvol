function do_minc_nlin_transfo(sourcefile,targetfile,par)

if ~exist('par')
  par='';
end

if ischar(par)
par.transfoname=par;
end
if ~isfield(par,'sge'),  par.sge=0; end



for nbsuj = 1:length(sourcefile)
  
  [outdir,sourcename] = fileparts(sourcefile{nbsuj});
  [pp,targetname] = fileparts(targetfile{nbsuj});
  
  outdir = fullfile(outdir,'tmp_minc');
  if exist(outdir)
    unix(sprintf('rm -f %s/*',outdir))
  end
  
  mkdir(outdir)
  
  %  anat_minc = fullfile(outdir,'c3_anat.mnc')
  %  epi_minc =  fullfile(outdir,'c3_epi.mnc')

  source_minc = sprintf('c3_source_%s',sourcename);
  target_minc =  sprintf('c3_target_%s',targetname);  
  
  CMD = sprintf('cd %s;\n',outdir);
  %convert to minc
  CMD = sprintf('%snii2mnc %s %s.mnc;\n',CMD,sourcefile{nbsuj},source_minc);
  CMD = sprintf('%snii2mnc %s %s.mnc;\n',CMD,targetfile{nbsuj},target_minc);
  
  %do some smooth
  
  CMD = sprintf('%s mincblur -fwhm 8 %s.mnc c3_target_8 ;\n',CMD,target_minc);
  CMD = sprintf('%s mincblur -fwhm 8 %s.mnc c3_source_8 ;\n',CMD,source_minc);

  CMD = sprintf('%s mincblur -fwhm 4 %s.mnc c3_target_4 ;\n',CMD,target_minc);
  CMD = sprintf('%s mincblur -fwhm 4 %s.mnc c3_source_4 ;\n',CMD,source_minc);

  CMD = sprintf('%s mincblur -fwhm 2 %s.mnc c3_target_2 ;\n',CMD,target_minc);
  CMD = sprintf('%s mincblur -fwhm 2 %s.mnc c3_source_2 ;\n',CMD,source_minc);

  CMD = sprintf('%s mritoself  %s.mnc %s.mnc source_to_target_lin.xfm -clobber ;\n',CMD,source_minc,target_minc);
 
  CMD = sprintf('%s minctracc -iterations 30 -step 8 8 8 -sub_lattice 6 -lattice_diam 24 24 24 -nonlinear corrcoeff -weight 1 -stiffness 1 -similarity 0.3 -transformation source_to_target_lin.xfm c3_source_8_blur.mnc c3_target_8_blur.mnc source_to_target_8_blur_nlin.xfm -clobber;\n',CMD);

  CMD = sprintf('%s minctracc -iterations 30 -step 4 4 4 -sub_lattice 6 -lattice_diam 12 12 12 -nonlinear corrcoeff -weight 1 -stiffness 1 -similarity 0.3 -transformation source_to_target_8_blur_nlin.xfm c3_source_4_blur.mnc c3_target_4_blur.mnc source_to_target_4_blur_nlin.xfm -clobber;\n',CMD);

  CMD = sprintf('%s minctracc -iterations 10 -step 2 2 2 -sub_lattice 6 -lattice_diam 6 6 6 -nonlinear corrcoeff -weight 1 -stiffness 1 -similarity 0.3 -transformation source_to_target_4_blur_nlin.xfm c3_source_2_blur.mnc c3_target_2_blur.mnc ../%s_nlin.xfm -clobber;\n',CMD,par.transfoname);

  CMD = sprintf('%sxfminvert ../%s_nlin.xfm ../%s_nlin_inv.xfm;\n',CMD,par.transfoname,par.transfoname);

  %CMD = sprintf('%s cp %s_nlin.xfm %s_nlin_inv.xfm ..;\n',CMD,par.transfoname,par.transfoname);
  
  ff=fopen(fullfile(outdir,'..','minc_nlin_transfo.log'),'a+');
  fprintf(ff,'\n\n%s\n%s',datestr(now),CMD);
  fclose(ff);
  
  if par.sge
    CMD = sprintf('#$ -S /bin/bash \n source /usr/cenir/bincenir/freesurfer5; \n %s ',CMD);
  job{nbsuj} = CMD;
  else
    unix(CMD)
  end
  
    
end


if par.sge
  par.jobname='minc_nlin';
  do_cmd_sge(job,par)
end
