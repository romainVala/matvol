function matlabbatch = job_image_calc(fi,fo,exp,interp,type,outdir)
%job_image_calc(fi,fo,exp,interp,type)
%type=2 uint8 4=int16 8=int32   16=Float32  64=Float64
%interp 0=none 1=trilinear 2  -2( -> -7)=2nd( -> 7th) Dregree Sinc

if ~exist('type'), type=4; end  %16 float 32
if ~exist('interp'), interp=1; end
if ~exist('outdir'), outdir=''; end

fi = cellstr(char(fi));

%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 2787 $)
%-----------------------------------------------------------------------
matlabbatch{1}.spm.util.imcalc.input = fi;
matlabbatch{1}.spm.util.imcalc.output = fo;
matlabbatch{1}.spm.util.imcalc.outdir = cellstr(outdir);
matlabbatch{1}.spm.util.imcalc.expression = exp;
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = interp;
matlabbatch{1}.spm.util.imcalc.options.dtype = type;
