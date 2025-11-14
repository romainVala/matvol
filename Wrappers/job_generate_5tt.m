function job =  job_generate_5tt(fanat,par)
%  JOB_GENERATE_5TT :
%                    Generate an image contains 5 five tissue types
% based on freesurfer segmentation or a T1-weighted image.
%
%
%       fanat : (cellstr) path to the images (freesurfer segmentation image or a
%               T1-weighted image), depends on the chosen algorithm.
%       
%       par   : matvol parameters structurs
%              
%             .algorithm :(char) name of the algorithm : freesurfer, fsl (fsl by default)
%             .output    :(char) name of the resolting image (5ttseg.nii by default)
%             .colorlut  :(char) path to 
%



if ~exist('par'), par=''; end;



defpar.algorithm = 'fsl';       % name of the algorithm : freesurfer, fsl
defpar.output    = '5ttseg.nii' % name of the output.

defpar.colorlut = '/network/lustre/iss01/cenir/software/irm/freesurfer7.0_centos08/FreeSurferColorLUT.txt';  % Default : FreeSurferColorLUT.txt
defpar.nthreads = 1;

defpar.sge      = 0;
defpar.jobname  = 'gen5tt';


par = complet_struct(par,defpar);
job={};

disp('module laod mrtrix and fsl');
%



for nbsuj = 1 : length(fanat)
    
    [dirAnat, theAnat] = get_parent_path(fanat{nbsuj},1)
    cmd = sprintf('cd %s',dirAnat);
    
    switch par.algorithm
        
        case 'freesurfer'
            
            cmd = sprintf('%s\n 5ttgen freesurfer %s %s', cmd, fanat{nbsuj},par.output)
            
        case 'fsl'
            
            cmd = sprintf('%s;\n 5ttgen fsl %s %s',cmd, fanat{nbsuj},par.output);
            
        otherwise
            error('Choose one of these algorithms : freesurfer, fsl')
            
            
    end
    
    %     if ~isempty(par.lmax)
    %         cmd = sprintf('%s -lmax %d',cmd,par.nthreads);
    %     end
    
    
    cmd = sprintf('%s -nthreads %d\n',cmd,par.nthreads);
    
    if par.sge
        job{end+1} = cmd;
    else
        unix(cmd)
    end
end

job = do_cmd_sge(job,par)

end


