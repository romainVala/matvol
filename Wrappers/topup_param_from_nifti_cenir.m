function  varargout = topup_param_from_nifti_cenir( finii,outdir )
%finii  = list of dicom file
%fidnifti  corresponding nifti file
%outdir

do_print=1;

if ~exist('outdir','var')
    do_print=0;
else
    outdir = outdir{1};
end

niftidir = get_parent_path(finii);
for k=1:length(niftidir)
    if exist(fullfile(niftidir{k},'dicom_info.mat'),'file')
        load(fullfile(niftidir{k},'dicom_info.mat'));
    elseif  exist(fullfile(niftidir{k},'..','dicom_info.mat'),'file')  %in case of use of preproce subdir
        load(fullfile(niftidir{k},'..','dicom_info.mat'))
    else
        error('can not find dicom_info.mat in the series data should be converted with cenir dicom_convert')
    end
    
    dicom_info(k) = hh;
end

if do_print
    fid = fopen(fullfile(outdir,'acqp.txt'),'w');
    fid2 = fopen(fullfile(outdir,'fileacqp.txt'),'w');
end

for k = 1:length(dicom_info)
    if k==66
        keyboard
    end
    
    h = dicom_info(k);
    if iscell(h),        h = h{1};    end
    
    hsession(k) = h.SeriesNumber;
    phase_angle = str2num(h.phase_angle);
    if isempty(phase_angle), phase_angle = 0;end
    switch h.PhaseEncodingDirection
        case 'COL '
            if phase_angle<0.1
                acqpval = '0 -1 0 0.050';
            elseif abs(phase_angle-pi)<0.1
                acqpval = '0 1 0 0.050';
            else
                error('what is the Y phase direciton <%f> in you  dicom!',phase_angle)
            end
        case 'ROW '
            if abs(phase_angle)<0.1%abs(phase_angle-pi/2)<0.1
                acqpval = '-1 0 0 0.050';
            elseif abs(abs(phase_angle)-pi/2)<0.1 %abs(phase_angle+pi/2)<0.1
                acqpval = '1 0 0 0.050';
            else
                error('what is the phase direciton in you fucking dicom!')
            end
            
        otherwise
            error('what is this phase axe <%s>', h.PhaseEncodingDirection)
    end
    ACQP(k,:) = str2num(acqpval);
    if do_print
        fprintf(fid,'%s\n',acqpval);
        fprintf(fid2,'%s \t%s\n',acqpval,finii{k}(1,:));
    end
end

varargout{1} = ACQP;

if do_print
    fclose(fid);fclose(fid2);
    
    [aa bb cc]= unique(hsession);
    fid = fopen(fullfile(outdir,'session.txt'),'w');
    fprintf(fid,'%d ',cc);
    fclose(fid);
    
    fid = fopen(fullfile(outdir,'index.txt'),'w');
    fprintf(fid,'%d ',1:length(dicom_info));
    fclose(fid);
    
    b=which('do_fsl_bin');
    fcnf = fullfile(fileparts(b),'b02b0.cnf');
    fcnf = r_movefile(fcnf,{outdir},'copy');
    
    %dim = read_dim_from_mosaic(h);
    vol = nifti_spm_vol(finii{1})
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
       error('can not do topup : tere is a unique phase direction for all acquisitions!')
    end
end


