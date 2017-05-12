function  varargout = topup_param_from_json_cenir( finii,outdir,fdic,line_for_each_volume )

if ~exist('line_for_each_volume','var'), line_for_each_volume=0;end
%finii  = list of dicom file
%fidnifti  corresponding nifti file
%outdir

do_print=1;

if ~exist('outdir','var')
    outdir='';
end

if isempty(outdir)
    do_print=0;
else
    outdir = outdir{1};
end

if nargin<3
    niftidir = get_parent_path(finii);
    
    try
        fdic = get_subdir_regex_files(niftidir,'^dic.*json',1) ;
        
    catch
        error('can not find json dicom parama ')
    end
end

if do_print
    fid = fopen(fullfile(outdir,'acqp.txt'),'w');
    fid2 = fopen(fullfile(outdir,'fileacqp.txt'),'w');
end

totfile=1;
for k = 1:length(finii)
    if line_for_each_volume
        v1=nifti_spm_vol(finii{k}); 
        nbline = length(v1);
    else
        nbline = size(finii{k},1); %put 1 line if 4D data
    end
    
    j=loadjson(fdic{k});
    
    for nbf=1:nbline
        hsession(totfile) = j.global.const.SeriesNumber;
        hseries(totfile) = k;
        if isfield(j.global.const,'sSliceArray_asSlice_0__dInPlaneRot')
            phase_angle =j.global.const.sSliceArray_asSlice_0__dInPlaneRot;
        else
            phase_angle = 0;
        end
        
        phase_dir = j.global.const.InPlanePhaseEncodingDirection;
if isfield(j.global.const,'PhaseEncodingDirectionPositive')
        phase_sign = j.global.const.PhaseEncodingDirectionPositive;
elseif isfield(j.global.const,'CsaImage_0x2E_PhaseEncodingDirectionPositive')
  phase_sign = j.global.const.CsaImage_0x2E_PhaseEncodingDirectionPositive;
end

if isfield(j.global.const,'BandwidthPerPixelPhaseEncode')
        hz =  j.global.const.BandwidthPerPixelPhaseEncode;
elseif isfield(j.global.const,'CsaImage_0x2E_PhaseEncodingDirectionPositive')
hz =  j.global.const.CsaImage_0x2E_PhaseEncodingDirectionPositive
end

        switch phase_dir
            case 'COL'
                if phase_sign
                    acqpval = sprintf('0 -1 0 %f',1/hz);
                else
                    acqpval = sprintf('0 1 0 %f',1/hz);
                end
                
            case 'ROW'
                if phase_sign
                    acqpval = sprintf('-1 0 0 %f',1/hz);
                else
                    acqpval = sprintf('1 0 0 %f',1/hz);
                end
                                
            otherwise
                error('what is this phase axe <%s>', phase_dir)
        end
        ACQP(totfile,:) = str2num(acqpval);
        if do_print
            fprintf(fid,'%s\n',acqpval);
            fprintf(fid2,'%s \t%s\n',acqpval,finii{k}(1,:));
        end
        
        totfile = totfile+1;
        
    end
    
end

varargout{1} = ACQP;
varargout{2} = hseries;

if do_print
    fclose(fid);fclose(fid2);
    
    [aa bb cc]= unique(hsession);
    fid = fopen(fullfile(outdir,'session.txt'),'w');
    fprintf(fid,'%d ',cc);
    fclose(fid);
    
    fid = fopen(fullfile(outdir,'index.txt'),'w');
    fprintf(fid,'%d ',1:length(hsession));
    fclose(fid);
    
    b=which('do_fsl_bin');
    fcnf = fullfile(fileparts(b),'b02b0.cnf');
    fcnf = r_movefile(fcnf,{outdir},'copy');
    
    %dim = read_dim_from_mosaic(h);
    vol = nifti_spm_vol(finii{1});
    dim=vol.dim;
    if dim(3)==1
        h=dicom_info(1); if iscell(h),        h = h{1};    end %problem pour les sequence B0_PAR non mosaic
        dim = read_dim_from_mosaic(h);
        if dim(3)==1
            error('pbr reading dim')
        end
    end
    
    if mod(dim(3),2)==0 %even number of slice
        fprintf('even number of slice keeping --subsamp=2,2,2,2,2,1,1,1,1\n');
    elseif mod(dim(3),3)==0
        fprintf('number of slice /3 so changing --subsamp=2,2,2,2,2,1,1,1,1  to --subsamp=3,3,3,3,3,1,1,1,1 \n');
        cmd = sprintf('sed -i -e ''4s/.*/--subsamp=3,3,3,3,3,1,1,1,1/'' %s',fcnf{1});
        unix(cmd);
        
    else
        fprintf('Please remove one slice to get an even number of slices\n\n')
        ffname = fullfile(outdir,'remove_one_slice');
        fid=fopen(ffname,'w');
        fprintf(fid,'%d %d %d',dim(1),dim(2),dim(3)-1); fclose(fid);
        
    end
    
    B = unique(ACQP,'rows');
    if size(B,1) == 1
        warning('can not do topup : tere is a unique phase direction for all acquisitions!')
    end
end


