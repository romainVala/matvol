function  job = job_do_dartel_template(frmg,frmb,par)
% job_do_dartel_template : SPM:Tools:DartelTools:RunDartel(create Templates)
%
% inputs :
%         frmg : file "rc1.*nii" (MG native space dartel import image) or "rp1.*nii"
%                can be a cellarray or volume object 
%         frmb : cellarray of file "rc2.*nii" (MB native space dartel import image) or "rp2.*nii"
%                can be a cellarray or volume object
%         par  : matvol parameters 
%
% output :
%         job  : SPM structure (create only  one job)
%         
%       output if using object
% ***   add volumes to exam object : addVolume [^u_ ]           , tag : 'flowfield'
%                              : (1).addVolume [^Template_6.nii], tag : 'template' (only the first subject)
%                       
%
% generates :
%         Dartel flow field (u_r*..) for all subjets
%         and templates images in the first forlder the 
%
%
%                                                                          
% default values adapted for vbm analysis
% for more information see : 
%                        https://www.fil.ion.ucl.ac.uk/~john/misc/VBMclass15.pdf  
%                         




if ~exist('par','var')
    par='';
end




obj = 0;
if isa(frmg,'volume')
    obj = 1;
    volumeArray  = frmg;
    frmg         = frmg.getPath;
    frmb         = frmb.getPath;
end

frmg = cellstr(frmg);
frmb = cellstr(frmb);


assert(~any(size(frmb)-size(frmg)), 'the tow inputs files must have the same size');


defpar.sge          = 0;
defpar.run          = 1;
defpar.display      = 0;
defpar.auto_add_obj = 0;
defpar.jobname      = 'template_vbm';
defpar.walltime     = '06:00:00';
defpar.mem          = '8G';
par = complet_struct(par,defpar);



job{1}.spm.tools.dartel.warp.images = {frmg frmb};


job{1}.spm.tools.dartel.warp.settings.template = 'Template';
job{1}.spm.tools.dartel.warp.settings.rform = 0;
job{1}.spm.tools.dartel.warp.settings.param(1).its = 3;
job{1}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
job{1}.spm.tools.dartel.warp.settings.param(1).K = 0;
job{1}.spm.tools.dartel.warp.settings.param(1).slam = 16;
job{1}.spm.tools.dartel.warp.settings.param(2).its = 3;
job{1}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
job{1}.spm.tools.dartel.warp.settings.param(2).K = 0;
job{1}.spm.tools.dartel.warp.settings.param(2).slam = 8;
job{1}.spm.tools.dartel.warp.settings.param(3).its = 3;
job{1}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
job{1}.spm.tools.dartel.warp.settings.param(3).K = 1;
job{1}.spm.tools.dartel.warp.settings.param(3).slam = 4;
job{1}.spm.tools.dartel.warp.settings.param(4).its = 3;
job{1}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
job{1}.spm.tools.dartel.warp.settings.param(4).K = 2;
job{1}.spm.tools.dartel.warp.settings.param(4).slam = 2;
job{1}.spm.tools.dartel.warp.settings.param(5).its = 3;
job{1}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
job{1}.spm.tools.dartel.warp.settings.param(5).K = 4;
job{1}.spm.tools.dartel.warp.settings.param(5).slam = 1;
job{1}.spm.tools.dartel.warp.settings.param(6).its = 3;
job{1}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
job{1}.spm.tools.dartel.warp.settings.param(6).K = 6;
job{1}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;
job{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
job{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
job{1}.spm.tools.dartel.warp.settings.optim.its = 3;


[ job ] = job_ending_rountines( job, [], par );


% add volume to exam obj using "frmg" object
if obj && par.auto_add_obj
     
  
    serie  = volumeArray.getSerie;
    npath = addprefixtofilenames(volumeArray.getPath(),'u_');
    for nvol = 1:length(npath)
        serie(nvol).addVolume('root',npath{nvol},'flowfield');
    end
    
    serie(1).addVolume('root',[serie(1).path 'Template_6.nii'],'template');
   
end


end 
