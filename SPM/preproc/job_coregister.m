function jobs = job_coregister(src,ref,other,par)
% JOB_COREGISTER - SPM:Spatial:Coregister
%
% INPUT : src - ref can be 'char' of volume(file), single-level 'cellstr' of volume(file), '@volume' array
%             other can be 'char' of volume(file),  multi-level 'cellstr' of volume(file), '@volume' array
%
% ref   -> remains static, it's the target
% src   -> will be moved to match the 'ref', this transformation will be used on 'other'
% other -> the transformation "src->ref" will be applied on 'other' images
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('other','var'), other = {}             ; end


if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - at least src & ref are required',mfilename)
end

obj = 0;
if isa(src,'volume')
    obj = 1;
    src_obj   = src;
    src       = src_obj.toJob(0);
    ref_obj   = ref;
    ref       = ref_obj.toJob(0);
    if size(other)>0
        other_obj = other;
        other     = other_obj.toJob(1);
    else
        other = volume.empty;
    end
else
    if isempty(other)       , other = {}             ; end
    if ~iscell(other)       , other = cellstr(other)'; end
    if ~iscell(src)         , src   = cellstr(src)   ; end
    if ~iscell(ref)         , ref   = cellstr(ref)'  ; end
end


%% defpar

defpar.type   = 'estimate';
defpar.interp = 1;
defpar.prefix = 'r';
defpar.sge    = 0;
defpar.redo   = 0;
defpar.run    = 0;
defpar.display= 0;

defpar.auto_add_obj = 1;

defpar.jobname  = 'spm_coreg';
defpar.walltime = '00:30:00';

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%% SPM:Spatial:Coregister

skip=[];

for nbsuj = 1:length(ref)
    
    %     if ~par.redo
    %         if is_hdr_realign(src(nbsuj)),  skip = [skip nbsuj];     fprintf('skiping suj %d becasue %s is realigned',nbsuj,src{nbsuj});       end
    %     end
    
    switch par.type
        case 'estimate'
            jobs{nbsuj}.spm.spatial.coreg.estimate.ref = ref(nbsuj); %#ok<*AGROW>
            jobs{nbsuj}.spm.spatial.coreg.estimate.source = src(nbsuj);
            if ~isempty(other)
                if iscell(other{nbsuj})
                    jobs{nbsuj}.spm.spatial.coreg.estimate.other = other{nbsuj};
                else
                jobs{nbsuj}.spm.spatial.coreg.estimate.other = cellstr(other{nbsuj});
                end
            end
            
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
            
        case 'estimate_and_write'
            
            jobs{nbsuj}.spm.spatial.coreg.estwrite.ref = ref(nbsuj);
            jobs{nbsuj}.spm.spatial.coreg.estwrite.source = src(nbsuj);
            if ~isempty(other)
                jobs{nbsuj}.spm.spatial.coreg.estwrite.other = cellstr(other{nbsuj});
            end
            
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
            
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.interp = par.interp;
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.mask = 0;
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.prefix = par.prefix;
            
        case 'write'
            
            jobs{nbsuj}.spm.spatial.coreg.write.ref = ref(nbsuj);
            jobs{nbsuj}.spm.spatial.coreg.write.source = cellstr(src{nbsuj});
            
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.interp = par.interp;
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.mask = 0;
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.prefix = par.prefix;
            
    end
    
    % skip if .coregistered file exists
    if ~par.redo
        coreg_file_source = coreg_filename(char(ref(nbsuj)),char(src(nbsuj)));
        if exist(coreg_file_source,'file')
            skip = [skip nbsuj];
            fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,nbsuj,coreg_file_source);
        end
    end
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Special routine for coregistration with matvol
% Write a matvol_coregistration_info.txt file to remember it has been done, and allow sckipping the next tine

if par.run % not for display
    
    for j = 1:length(jobs)
        
        % Content of the file
        str = gencode(jobs{j}); % generate matlabbatch code
        %field job coreg can either be in estimate or estwrite
        if isfield(jobs{j}.spm.spatial.coreg,'estimate')
            jobcoreg = jobs{j}.spm.spatial.coreg.estimate;
        elseif isfield(jobs{j}.spm.spatial.coreg,'estwrite')
            jobcoreg = jobs{j}.spm.spatial.coreg.estwrite;
        elseif isfield(jobs{j}.spm.spatial.coreg,'write')
            jobcoreg = jobs{j}.spm.spatial.coreg.write;
        end
        
        % Source : Where to write the file ?
        coreg_file_source = coreg_filename(char(jobcoreg.ref),char(jobcoreg.source));
        write_in_text_file(coreg_file_source, str)
        
        % Other : Where to write the file ?
        if isfield(jobcoreg,'other')
            for o = 1:length(jobcoreg.other)
                coreg_file_other = coreg_filename(char(jobcoreg.ref),char(jobcoreg.other{o}));
                write_in_text_file(coreg_file_other, str)
            end
        end
        
    end
    
end


%% Add outputs objects

if obj && par.auto_add_obj
    
    serieArray = [src_obj.serie];
    tag        =  src_obj(1).tag;
    ext        = '.*.nii$';
    
    switch par.type
        case 'estimate'
            % pass, no volume created
        case 'estimate_and_write'
            serieArray.addVolume(['^' par.prefix tag ext],[par.prefix tag])
        case 'write'
            serieArray.addVolume(['^' par.prefix tag ext],[par.prefix tag])
    end
    
    if ~isempty(other)
        
        switch par.type
            case 'estimate'
                % pass, no volume created
            case 'estimate_and_write'
                serieArray.addVolume(['^' par.prefix tag ext],[par.prefix tag])
            case 'write'
                serieArray.addVolume(['^' par.prefix tag ext],[par.prefix tag])
        end
        
    end
    
end


end % function

%--------------------------------------------------------------------------
function filename = coreg_filename(ref,src)

[~       , ref_name, ~] = fileparts(ref);
[src_path, src_name, ~] = fileparts(src);
filename = fullfile(src_path,sprintf('matvol_coreg_info___%s___%s.txt',ref_name,src_name));

end % function

%--------------------------------------------------------------------------
function write_in_text_file(filename, content)

assert(iscellstr(content) && isvector(content))

fileID = fopen( filename , 'w' , 'n' , 'UTF-8' );
if fileID < 0
    warning('[%s]: Could not open %s', mfilename, filename)
end

fprintf(fileID,'%s\n',content{:});

fclose(fileID);

end % function
