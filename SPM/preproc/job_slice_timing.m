function jobs = job_slice_timing(fin,par)
% JOB_SLICE_TIMING - SPM:Temporal:SliceTiming
%
% INPUT : fin can be 'char' of dir, multi-level 'cellstr' of dir, '@volume' array
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - fin is required',mfilename)
end

obj = 0;
if isa(fin,'volume')
    obj = 1;
    fin_obj  = fin;
    fin = fin_obj.toJob(1);
end


%% defpar

defpar.TR     = 0;
defpar.prefix = 'a';

defpar.file_reg        = '^f.*nii';

defpar.reference_slice = 'middle'; % first / middle / last / sliceNumber (integer)

defpar.use_JSON        = 1;
defpar.use_JSON_regex  = 'json$';

defpar.slice_order     = 'interleaved_ascending'; % only usefull when par.use_JSON=0

defpar.sge      = 0;
defpar.jobname  ='spm_sliceTime';
defpar.walltime = '04:00:00';

defpar.auto_add_obj = 1;

defpar.run     = 1;
defpar.display = 0;
defpar.redo    = 0;

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%% SPM:Temporal:SliceTiming

% obj : unzip if necessary
if obj
    fin_obj.unzip(par);
    fin = fin_obj.toJob(1);
end

if iscell( fin{1} )
    nSubj = length(fin);
else
    nSubj = 1;
end

skip = [];

for subj=1:nSubj
    
    if obj
        if iscell(fin{subj})
            subjFiles = fin{subj};
        else
            subjFiles = fin;
        end
    else
        if iscell(fin{1})
            subjFiles = get_subdir_regex_files(fin{subj}, par.file_reg);
            unzip_volume(subjFiles); % unzip if necessary
            subjFiles = get_subdir_regex_files(fin{subj}, par.file_reg);
        else
            subjFiles = fin;
        end
    end
    
    for n=1:length(subjFiles)
        currentFiles = cellstr(subjFiles{n}) ;
        
        % skip if output already exists
        fout = addprefixtofilenames(currentFiles(end),par.prefix);
        if ~par.redo   &&   exist(fout{1}, 'file')
            skip = [skip subj];
            fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,fout{1});
            continue
        else
            
        end
        
        if length(currentFiles) == 1 % 4D file
            filesReady = spm_select('expand',currentFiles)';
        else
            filesReady = currentFiles;
        end
        jobs{subj}.spm.temporal.st.scans{n} = filesReady'; %#ok<*AGROW>
        
    end
    
    if par.use_JSON
        
        if obj
            json = get_subdir_regex_files( get_parent_path(fin{subj}), par.use_JSON_regex, struct('verbose',0) );
        else
            json = get_subdir_regex_files( fin{subj}, par.use_JSON_regex, struct('verbose',0) );
        end
        if isempty(json)
            error('no JSON found with regex [ %s ] in dir : %s', par.use_JSON_regex, fin{subj})
        else
            json = deblank(json{1}(1,:)); % only take the first one, we assume all volumes have the same TR, nrSlices, ...
        end
        res = get_string_from_json(json, {'CsaSeries.MrPhoenixProtocol.sSliceArray.lSize', 'RepetitionTime', 'CsaImage.MosaicRefAcqTimes'}, {'num', 'num', 'vect'});
        nrSlices    = res{1};
        TR          = res{2}/1000; % millisecond -> second
        sliceonsets = res{3};      % keep millisecond
        
        assert( max(sliceonsets)/1000 <= TR , ' slice onset > TR ! pb with the JSON ? pb unit conversion ?' )
        
        unique_sliceonsets = unique(sliceonsets); % in case of MB sequence
        
        % Refslice is milliseconds
        switch par.reference_slice
            case 'first'
                refslice = unique_sliceonsets(1);
            case 'middle'
                refslice = unique_sliceonsets( round( length(unique_sliceonsets)/2 ) ); % i.e. middle of the vector unique_sliceonsets
            case 'last'
                refslice = unique_sliceonsets(end);
            otherwise
                refslice = par.reference_slice; % in millisecond !!
        end
        
        jobs{subj}.spm.temporal.st.so       = sliceonsets;
        jobs{subj}.spm.temporal.st.refslice = refslice;
        
        TA = 0; % not relevent for slice timing in ms
        
    else
        
        V        = spm_vol( subjFiles{1}(1,:) );
        nrSlices = V(1).dim(3);
        if par.TR > 0
            TR = par.TR;
        else
            TR = V(1).private.timing.tspace;
        end
        
        parameters.slicetiming.slice_order = par.slice_order;
        parameters.slicetiming.reference_slice = par.reference_slice;
        
        [slice_order,ref_slice] = get_slice_order(parameters,nrSlices);
        
        jobs{subj}.spm.temporal.st.so = slice_order;
        jobs{subj}.spm.temporal.st.refslice = ref_slice;
        
        TA = TR - (TR/nrSlices);
        
    end
    
    jobs{subj}.spm.temporal.st.nslices = nrSlices;
    jobs{subj}.spm.temporal.st.tr      = TR;
    jobs{subj}.spm.temporal.st.ta      = TA;
    jobs{subj}.spm.temporal.st.prefix  = 'a';
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects

if obj && par.auto_add_obj && par.run
    
    serieArray = [fin_obj.serie];
    tag        =  {fin_obj.tag};
    ext        = '.*.nii$';
    
    for vol = 1 : numel(fin_obj)
        serieArray(vol).addVolume(['^' par.prefix tag{vol} ext],[par.prefix tag{vol}])
    end
    
end


end % function
