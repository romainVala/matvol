function job_dynamic_R2s(input4D, mask, par)
% JOB_DYNAMIC_R2S computes { R2s, T2s = 1/R2s, S0, ERR } for each TR of each voxel. A temporal mean of each 4D will aslo be computed
% Input data must be multi-echo GRE : the model is multi-TE mono-exponential decay.
% Designed ot work on 4D data (fMRI) but it also works on 3D data.
%
% MODEL
%   Use log-linear leat-square estimation of R2s and S0 parameters
%
%       S(x,y,z,t,TE)  =     S0(x,y,z,t)  * exp(-R2s(x,y,z,t,TE)*TE)  =>  R2s exponential decay
%   log(S(x,y,z,t,TE)) = log(S0(x,y,z,t)) -      R2s(x,y,z,t,TE)*TE   =>  when log transformed, the equation becomes linear
%
%   R2s and S0 are estimated using a least-square estimation
%   https://mathworks.com/help/curvefit/least-squares-fitting.html
%
%   The computation time of paramters R2s and S0 is bellow 1 second on a modern CPU, due to MATLAB vectorized (internally parallel) computation.
%   -> All voxels R2s and S0 of each TR are computed in one single opreration.
%
% SYNTAX
%   job_dynamic_R2s(input4D, mask)
%   job_dynamic_R2s(input4D, mask, par)
%
% INPUTS
% - input4D : single-level cellstr of file names
%        OR : @volume array
%             -> it works on 3D data, such as multi-echo 3D GRE for QSM
%
% - mask    : single-level cellstr of file names
%        OR : @volume array
%
% - par     : standard matlavol structure => check parameters bellow, in the 'defpar' section
% 
% NOTES
%   There is several ways to fetch the TEs, they are performed <<< in this order >>> :
%   - give it using par.TE = [15 30 45]
%     WARNING : in this case, only this single TE vector will be used for each input volumes. It does not work with 3 TE + 5 echos
%   - give a list of dcm2niix .json files with using par.json = {'/pth/to/e1.json','/pth/to/e2.json',...}
%   - if you use @volume array as input, it will try to find the @json in the same @serie
%
%
% See also get_subdir_regex_files exam exam.AddSerie serie.addVolume exam.getSerie serie.getVolume

if nargin==0, help(mfilename), return, end

narginchk(2,3)


%% Check input arguments

if ~exist('par'      ,'var'), par       = ''; end
% if ~exist('jobappend','var'), jobappend = ''; end

obj = 0;
if isa(input4D,'volume')
    obj          = 1;
    
    input4D_obj  = input4D;
    input4D      = input4D_obj.toJob(); % .toJob converts to cellstr
    
    mask_obj     = mask;
    mask         = mask_obj   .toJob();
    
    try
        json_list = input4D_obj(:,1).getSerie().getJson().toJob();
    catch ME %#ok<NASGU> 
        warining('could not find any @json in the @serie')
    end
    
end

% specific paramters
defpar.TE   = []; % try to fetch it (objects) or let the user fill it
defpar.json = []; % use json to fetch TE

% I/O
defpar.prefix_T2s   =  'T2s_';
defpar.prefix_R2s   =  'R2s_';
defpar.prefix_S0    =   'S0_';
defpar.prefix_ERR   =  'ERR_';
defpar.prefix_mean  = 'mean_'; % will be concatenated // ex : mean_T2s_<input.nii>

% cluster
defpar.sge          = 0;
defpar.jobname      = mfilename;
defpar.mem          = '16G'; % ????
defpar.walltime     = '04:00:00';

% matvol classics
defpar.run          = 1;
defpar.redo         = 0;
defpar.verbose      = 1;
defpar.auto_add_obj = 1;

par = complet_struct(par,defpar);

% retrocompatibility
if par.redo
    par.skip = 0;
end


%% Lmitations

assert(~par.sge, 'par.sge=1 not working with this purely matlab code')


%% check TE source

if isempty(par.TE)
    if isempty(par.json)
        if exist('json_list','var')
            par.json = json_list;
        else
            error('no par.TE, no par.json, no @json(objects) found')
        end
    else
        % pass, load TE later...
    end
else
    TE = par.TE(:)'; % force line vector
end


%% main

nFile = length(input4D);

out_T2s      = cell(nFile,1);
out_R2s      = cell(nFile,1);
out_S0       = cell(nFile,1);
out_ERR      = cell(nFile,1);
out_mean_T2s = cell(nFile,1);
out_mean_R2s = cell(nFile,1);
out_mean_S0  = cell(nFile,1);
out_mean_ERR = cell(nFile,1);

for iFile = 1 : nFile
    in = input4D{iFile};
    
    out_T2s     {iFile} = addprefixtofilenames(in(1,:)       , par.prefix_T2s);
    out_R2s     {iFile} = addprefixtofilenames(in(1,:)       , par.prefix_R2s);
    out_S0      {iFile} = addprefixtofilenames(in(1,:)       , par.prefix_S0 );
    out_ERR     {iFile} = addprefixtofilenames(in(1,:)       , par.prefix_ERR);
    out_mean_T2s{iFile} = addprefixtofilenames(out_T2s{iFile}, par.prefix_mean);
    out_mean_R2s{iFile} = addprefixtofilenames(out_R2s{iFile}, par.prefix_mean);
    out_mean_S0 {iFile} = addprefixtofilenames(out_S0 {iFile}, par.prefix_mean);
    out_mean_ERR{iFile} = addprefixtofilenames(out_ERR{iFile}, par.prefix_mean);
    
    if exist(out_R2s{iFile},'file') && ~par.redo
        fprintf('[%s]: %d/%d => skip, output file exists %s \n', mfilename, iFile, nFile, out_R2s{iFile})
        continue
    else
        fprintf('[%s]: %d/%d => working on %s \n', mfilename, iFile, nFile, in(1,:))
    end
    
    % fetch TE values
    if isempty(par.TE) && ~isempty(par.json)
        json_file = cellstr(char(par.json{iFile}));
        nTE = length(json_file);
        TE = zeros(1,nTE);
        for iJson = 1 : nTE
            content = spm_jsonread(json_file{iJson});
            assert(isfield(content,'ConversionSoftware'), 'json file come from dcm2niix conversion')
            TE(iJson) = 1000 * content.EchoTime; % second -> millisecond
        end % iJson
    end

    % load mask
    Vm = spm_vol(mask{iFile});
    Ym = spm_read_vols(Vm);
    nMoxel = sum(Ym(:)); % nMoxel = number of voxel in mask
    
    % load input volumes
    Vi = spm_vol(cellstr(in));
    Vi = [Vi{:}];
    [nTR, nTE] = size(Vi);
    size3D = Vi(1).dim;
    nVoxel = prod(size3D);
    
    % Y dimentions are : [X Y Z T E]
    Y = NaN([size3D nTR nTE]);
    fprintf('[%s]: loading input4D... ', mfilename)
    t0 = tic;
    for iVol = 1:nTE
        Y(:,:,:,:,iVol) = spm_read_vols(Vi(:,iVol)); % (I/O intensive)
    end
    fprintf('done in %gs \n', toc(t0))
    
    % [X Y Z T E] -> [X*Y*Z T E] (prepare for masking)
    Y = reshape(Y, [nVoxel nTR nTE]);
    
    % keep voxels in mask : [X*Y*Z T E] -> [mask(X*Y*Z) T E] 
    Y(~Ym(:),:,:) = [];
    
    % apply log (for log-linear fit)
    Y = log(Y);
    
    % pre-allocate outputs : [mask(X*Y*Z) T]
    r2s = NaN([nMoxel nTR]);
    s0  = NaN([nMoxel nTR]);
    err = NaN([nMoxel nTR]);
    
    % fit
    fprintf('[%s]: start fit... ', mfilename)
    t0 = tic;
    for iTR = 1 : nTR
        % https://mathworks.com/help/curvefit/least-squares-fitting.html
        b1 = ...
            ( nTE * sum( TE .* squeeze(Y(:,iTR,:)), 2 )   -   sum(TE).*sum(squeeze(Y(:,iTR,:)), 2 ) ) / ...
            ( nTE * sum( TE.^2 )    -    sum( TE )^2 );
        b2 = ( 1/nTE ) * (sum(squeeze(Y(:,iTR,:)), 2 )    -    b1 * sum(TE));
        r2s(:, iTR) =    -b1;
        s0 (:, iTR) = exp(b2);
        err(:, iTR) = sum( ( squeeze(Y(:,iTR,:)) - (b1.*TE + b2) ).^2 , 2 );
        % !!! forget about polyfit, it's not in vectorized, so it's very slow... but the result is exactly the same !!!
        %         parfor iMoxel = 1 : nMoxel
        %             p = polyfit(TE,Y(iMoxel, iTR,:),1);
        %             R2s(iMoxel, iTR) =    -p(1);
        %             S0 (iMoxel, iTR) = exp(p(2));
        %         end % iMoxel
    end % iTR
    fprintf('done in %gs \n', toc(t0));
    
    clear b1 b2 Y; % save memory
    
    % [mask(X*Y*Z) T] -> [X*Y*Z T] -> [X Y Z T]
    R2s            = NaN([nVoxel nTR]);
    T2s            = NaN([nVoxel nTR]);
    S0             = NaN([nVoxel nTR]);
    ERR            = NaN([nVoxel nTR]);
    R2s(Ym(:)>0,:) =    r2s*1000;
    T2s(Ym(:)>0,:) = 1./r2s;
    S0 (Ym(:)>0,:) =     s0;
    ERR(Ym(:)>0,:) =    err;
    R2s            = reshape(R2s, [size3D nTR]);
    T2s            = reshape(T2s, [size3D nTR]);
    S0             = reshape(S0 , [size3D nTR]);
    ERR            = reshape(ERR, [size3D nTR]);
    
    clear r2s s0 err; % save memory
    
    % threshold, mostly for auto-range detection at visualization
    limR2s            = 1000; % 1/s
    R2s(R2s  > limR2s) = limR2s;
    R2s(R2s  <      0) = 0;
    limT2s            = 200; % ms
    T2s(T2s  > limT2s) = limT2s;
    T2s(T2s  <      0) = 0;
    T2s(R2s <=      0) = limT2s; % this a special case because of 1/0 problem
    
    % write output files (I/O intensive)
    fprintf('[%s]: writing outputs... ', mfilename)
    t0 = tic;
    write_4D(          R2s              , Vi(1),      out_R2s{iFile},      'log-lin R2s (1/s)')
    write_4D(          T2s              , Vi(1),      out_T2s{iFile},      'log-lin T2s  (ms)')
    write_4D(           S0              , Vi(1),      out_S0 {iFile},      'log-lin S0'       )
    write_4D(          ERR              , Vi(1),      out_ERR{iFile},      'log-lin ERR'      )
    if nTR > 1
        write_3D( mean(R2s,4, 'omitnan'), Vi(1), out_mean_R2s{iFile}, 'mean log-lin R2s (1/s)')
        write_3D( mean(T2s,4, 'omitnan'), Vi(1), out_mean_T2s{iFile}, 'mean log-lin T2s  (ms)')
        write_3D( mean(S0 ,4, 'omitnan'), Vi(1), out_mean_S0 {iFile}, 'mean log-lin S0'       )
        write_3D( mean(ERR,4, 'omitnan'), Vi(1), out_mean_ERR{iFile}, 'mean log-lin ERR'      )
    end
    fprintf('done in %gs \n', toc(t0));
    
    clear R2s T2s S0 ERR; % save memory
    
end % iFile


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    if ndims(input4D_obj) == 3
        input4D_obj = input4D_obj(:,:,1);
    end
    
    for iVol = 1 : length(input4D_obj)
        
        % Shortcut
        vol = input4D_obj(iVol);
        ser = vol.serie;
        tag = vol.tag;
        sub = vol.subdir;
        
        if par.run
            ext  = '.*.nii';
            ser.addVolume(sub, ['^'                     par.prefix_T2s tag ext], [                par.prefix_T2s tag], 1)
            ser.addVolume(sub, ['^'                     par.prefix_R2s tag ext], [                par.prefix_R2s tag], 1)
            ser.addVolume(sub, ['^'                     par.prefix_S0  tag ext], [                par.prefix_S0  tag], 1)
            ser.addVolume(sub, ['^'                     par.prefix_ERR tag ext], [                par.prefix_ERR tag], 1)
            if nTR > 1
                ser.addVolume(sub, ['^' par.prefix_mean par.prefix_T2s tag ext], [par.prefix_mean par.prefix_T2s tag], 1)
                ser.addVolume(sub, ['^' par.prefix_mean par.prefix_R2s tag ext], [par.prefix_mean par.prefix_R2s tag], 1)
                ser.addVolume(sub, ['^' par.prefix_mean par.prefix_S0  tag ext], [par.prefix_mean par.prefix_S0  tag], 1)
                ser.addVolume(sub, ['^' par.prefix_mean par.prefix_ERR tag ext], [par.prefix_mean par.prefix_ERR tag], 1)
            end
        elseif par.sge
            ser.addVolume('root', addprefixtofilenames(vol.path,                     par.prefix_T2s ), [                par.prefix_T2s tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,                     par.prefix_R2s ), [                par.prefix_R2s tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,                     par.prefix_S0  ), [                par.prefix_S0  tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,                     par.prefix_ERR ), [                par.prefix_ERR tag])
            if nTR > 1
                ser.addVolume('root', addprefixtofilenames(vol.path,[par.prefix_mean par.prefix_T2s]), [par.prefix_mean par.prefix_T2s tag])
                ser.addVolume('root', addprefixtofilenames(vol.path,[par.prefix_mean par.prefix_R2s]), [par.prefix_mean par.prefix_R2s tag])
                ser.addVolume('root', addprefixtofilenames(vol.path,[par.prefix_mean par.prefix_S0 ]), [par.prefix_mean par.prefix_S0  tag])
                ser.addVolume('root', addprefixtofilenames(vol.path,[par.prefix_mean par.prefix_ERR]), [par.prefix_mean par.prefix_ERR tag])
            end
        end
        
    end % iVol
    
end % obj


end % function

function write_4D(mx, header, name, descrip)
assert(~strcmp(header.fname,name))
new = header.private;
new.dat.fname = name;
new.dat.dtype = 'FLOAT32';
new.descrip   = descrip;
create(new);
new.dat(:,:,:,:) = mx;
end % function

function write_3D(mx, header, name, descrip)
assert(~strcmp(header.fname,name))
new = header;
new.fname   = name;
new.dt(1)   = spm_type('float32');
new.descrip = descrip;
spm_write_vol(new,mx);
end % function
