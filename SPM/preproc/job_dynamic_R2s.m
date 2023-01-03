function job_dynamic_R2s(input4D, mask, par)
%JOB_DYNAMIC_R2S
%
% job_dynamic_R2s will use 3dTstat with options -mean, -stdev, -tsnr
%
% SYNTAX :
%
% EXAMPLE
%
% INPUTS :
% - fin : single-level cellstr of file names
% OR
% - fin : @volume array
%
% See also get_subdir_regex_files exam exam.AddSerie serie.addVolume exam.getSerie serie.getVolume

if nargin==0, help(mfilename), return, end

narginchk(2,3)


%% Check input arguments

if ~exist('par'      ,'var'), par       = ''; end
if ~exist('jobappend','var'), jobappend = ''; end

obj = 0;
if isa(input4D,'volume')
    obj          = 1;
    
    input4D_obj  = input4D;
    input4D      = input4D_obj.toJob(); % .toJob converts to cellstr
    
    mask_obj     = mask;
    mask         = mask_obj   .toJob();
    
    try
        json_list = input4D_obj(:,1).getSerie().getJson().toJob();
    catch ME
        warining('could not find any @json in the @serie')
    end
    
end

% specific paramters
defpar.TE   = []; % try to fetch it (objects) or let the user fill it
defpar.json = []; % use json to fetch TE

% I/O
defpar.prefix_T2s  =  'T2s_';
defpar.prefix_R2s  =  'R2s_';
defpar.prefix_S0   =   'S0_';
defpar.prefix_mean = 'mean_'; % will be concatenated // ex : mean_T2s_<input.nii>

defpar.sge               = 0;
defpar.jobname           = 'job_dynamic_R2s';
defpar.mem               = '16G'; % ????

defpar.run               = 1;
defpar.redo              = 0;
defpar.verbose           = 1;
defpar.auto_add_obj      = 1;

par = complet_struct(par,defpar);

% retrocompatibility
if par.redo
    par.skip = 0;
end

% check TE source
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
out_mean_T2s = cell(nFile,1);
out_mean_R2s = cell(nFile,1);
out_mean_S0  = cell(nFile,1);
skip         = [];
for iFile = 1 : nFile
    in = input4D{iFile};
    
    out_T2s     {iFile} = addprefixtofilenames(in(1,:)       , par.prefix_T2s );
    out_R2s     {iFile} = addprefixtofilenames(in(1,:)       , par.prefix_R2s);
    out_S0      {iFile} = addprefixtofilenames(in(1,:)       , par.prefix_S0 );
    out_mean_T2s{iFile} = addprefixtofilenames(out_T2s{iFile}, par.prefix_mean );
    out_mean_R2s{iFile} = addprefixtofilenames(out_R2s{iFile}, par.prefix_mean);
    out_mean_S0 {iFile} = addprefixtofilenames(out_S0 {iFile}, par.prefix_mean );
    
    if exist(out_mean_S0{iFile},'file') && ~par.redo
        fprintf('[%s]: %d/%d => skip, output file exists %s \n', mfilename, iFile, nFile, out_mean_S0{iFile})
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
    nMoxel = sum(Ym(:));
    
    % load input volumes
    Vi = spm_vol(cellstr(in));
    Vi = [Vi{:}];
    [nTR, nTE] = size(Vi);
    size3D = Vi(1).dim;
    nVoxel = prod(size3D);
    
    % Y dimentions are : X Y Z T E
    Y = NaN([size3D nTR nTE]);
    fprintf('[%s]: loading input4D... ', mfilename)
    t0 = tic;
    for iVol = 1:nTE
        Y(:,:,:,:,iVol) = spm_read_vols(Vi(:,iVol));
    end
    fprintf('done in %gs \n', toc(t0))
    
    % X Y Z T E -> X*Y*Z T E
    Y = reshape(Y, [nVoxel nTR, nTE]);
    
    % keep voxels in mask
    Y(~Ym(:),:,:) = [];
    
    % apply log
    Y = log(Y);
    
    % pre-allocate outputs : *Y*Z T E
    r2s = NaN([nMoxel nTR]);
    s0  = NaN([nMoxel nTR]);
    
    % fit
    fprintf('[%s]: start fit... ', mfilename)
    t0 = tic;
    for iTR = 1 : nTR
        %         fprintf('TR = %d \n', iTR)
        % https://fr.mathworks.com/help/curvefit/least-squares-fitting.html
        b1 = ...
            ( nTE * sum( TE .* squeeze(Y(:,iTR,:)), 2 )   -   sum(TE).*sum(squeeze(Y(:,iTR,:)), 2 ) ) / ...
            ( nTE * sum( TE.^2 )    -    sum( TE )^2 );
        b2 = ( 1/nTE ) * (sum(squeeze(Y(:,iTR,:)), 2 )    -    b1 * sum(TE));
        r2s(:, iTR) =    -b1;
        s0 (:, iTR) = exp(b2);
        %         parfor iMoxel = 1 : nMoxel
        %             p = polyfit(TE,Y(iMoxel, iTR,:),1);
        %             R2s(iMoxel, iTR) =    -p(1);
        %             S0 (iMoxel, iTR) = exp(p(2));
        %         end % iMoxel
    end % iTR
    fprintf('done in %gs \n', toc(t0));
    
    clear b1 b2 Y; % we need to save memory...
    
    R2s = NaN([nVoxel nTR]);
    T2s = NaN([nVoxel nTR]);
    S0  = NaN([nVoxel nTR]);
    
    R2s(Ym(:)>0,:) =    r2s*1000;
    T2s(Ym(:)>0,:) = 1./r2s;
    S0 (Ym(:)>0,:) =    s0;
    
    clear r2s s0; % we need to save memory...
    
    lim = 1000; % 1/s
    R2s(R2s>lim) = lim;
    R2s(R2s<0  ) = 0;
    
    lim = 200; % ms
    T2s(T2s>lim) = lim;
    T2s(T2s<0  ) = 0;
    
    R2s = reshape(R2s, [size3D nTR]);
    T2s = reshape(T2s, [size3D nTR]);
    S0  = reshape(S0 , [size3D nTR]);
    
    fprintf('[%s]: writing outputs... ', mfilename)
    t0 = tic;
    
    write_4D( R2s, Vi(1), out_R2s{iFile}, 'log-lin R2s  (s)')
    write_4D( T2s, Vi(1), out_T2s{iFile}, 'log-lin T2s (ms)')
    write_4D( S0 , Vi(1), out_S0 {iFile}, 'log-lin S0'      )
    
    write_3D( mean(R2s,4), Vi(1), out_mean_R2s{iFile}, 'mean log-lin R2s  (s)')
    write_3D( mean(T2s,4), Vi(1), out_mean_T2s{iFile}, 'mean log-lin T2s (ms)')
    write_3D( mean(S0 ,4), Vi(1), out_mean_S0 {iFile}, 'mean log-lin S0'      )
    fprintf('done in %gs \n', toc(t0));
    
    clear R2s T2s S0; % we need to save memory...
    
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
            
            ser.addVolume(sub, ['^'                 par.prefix_T2s tag ext],[                par.prefix_T2s tag],1)
            ser.addVolume(sub, ['^'                 par.prefix_R2s tag ext],[                par.prefix_R2s tag],1)
            ser.addVolume(sub, ['^'                 par.prefix_S0  tag ext],[                par.prefix_S0  tag],1)
            ser.addVolume(sub, ['^' par.prefix_mean par.prefix_T2s tag ext],[par.prefix_mean par.prefix_T2s tag],1)
            ser.addVolume(sub, ['^' par.prefix_mean par.prefix_R2s tag ext],[par.prefix_mean par.prefix_R2s tag],1)
            ser.addVolume(sub, ['^' par.prefix_mean par.prefix_S0  tag ext],[par.prefix_mean par.prefix_S0  tag],1)
            
        elseif par.sge
            
            ser.addVolume('root', addprefixtofilenames(vol.path,par.prefix_T2s),[par.prefix_T2s tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,par.prefix_R2s),[par.prefix_R2s tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,par.prefix_S0 ),[par.prefix_S0  tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,[par.prefix_mean par.prefix_T2s]),[par.prefix_mean par.prefix_T2s tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,[par.prefix_mean par.prefix_R2s]),[par.prefix_mean par.prefix_R2s tag])
            ser.addVolume('root', addprefixtofilenames(vol.path,[par.prefix_mean par.prefix_S0 ]),[par.prefix_mean par.prefix_S0  tag])
            
        end
        
    end % iVol
    
end % obj


end % function

function write_4D(mx, header, name, descrip)
    new = header.private;
    new.dat.fname = name;
    new.dat.dtype = 'FLOAT64';
    new.descrip   = descrip;
    create(new);
    new.dat(:,:,:,:) = mx;
end % function

function write_3D(mx, header, name, descrip)
    new = header;
    new.fname   = name;
    new.dt(1)   = spm_type('float32');
    new.descrip = descrip;
    spm_write_vol(new,mx);
end % function
