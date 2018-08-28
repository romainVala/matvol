function jobs = job_slice_timing(fin,par)
% JOB_SLICE_TIMING - SPM:Temporal:SliceTiming
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%

%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

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

defpar.run     = 1;
defpar.display = 0;
defpar.redo    = 0;

par = complet_struct(par,defpar);


%% SPM:Temporal:SliceTiming

if iscell( fin{1} )
    nSubj = length(fin);
else
    nSubj = 1;
end

skip = [];

for subj=1:nSubj
    
    if iscell(fin{1})
        subjFiles = get_subdir_regex_files(fin{subj}, par.file_reg);
        unzip_volume(subjFiles);
        subjFiles = get_subdir_regex_files(fin{subj}, par.file_reg);
    else
        subjFiles = fin;
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
            V = spm_vol(currentFiles{1});
            for k=1:length(V)
                filesReady{k} = sprintf('%s,%d',currentFiles{1},k);
            end
        else
            filesReady = currentFiles;
        end
        jobs{subj}.spm.temporal.st.scans{n} = filesReady'; %#ok<*AGROW>
        
    end
    
    if par.use_JSON
        
        json = get_subdir_regex_files( fin{subj}, par.use_JSON_regex );
        if isempty(json)
            error('no JSON found with regex [ %s ] in dir : %s', par.use_JSON_regex, fin{subj})
        else
            json = json{1}; % only take the first one, we assume all volumes have the same TR, nrSlices, ...
        end
        res = get_string_from_json(json, {'CsaSeries.MrPhoenixProtocol.sSliceArray.lSize', 'RepetitionTime', 'CsaImage.MosaicRefAcqTimes'}, {'num', 'num', 'vect'});
        nrSlices    = res{1};
        TR          = res{2}/1000; % ms -> s
        sliceonsets = res{3}; % keep ms
        
        % here refslice is in slice number (integer)
        switch par.reference_slice
            case 'first'
                refslice = 1;
            case 'middle'
                refslice = round(nrSlices/2);
            case 'last'
                refslice = nrSlices;
            otherwise
                refslice = par.slice_to_realign; % integer
        end
        
        % now we convert slice number (integer) in slice timing (float, milliseconds)
        refslice = sliceonsets(refslice);
        
        jobs{subj}.spm.temporal.st.so = sliceonsets;
        jobs{subj}.spm.temporal.st.refslice = refslice;
        
        TA = 0; % not relevent for slice timing in ms
        
    else
        
        V        = spm_vol( subjFiles{1}(1,:) );
        nrSlices = V(1).dim(3);
        TR       = V(1).private.timing.tspace;
        
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


end % function
