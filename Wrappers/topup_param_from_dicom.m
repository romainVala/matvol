function  topup_param_from_dicom( fidic,outdir )
%fidic  = list of dicom file
%fidnifti  corresponding nifti file
%outdir

outdir = outdir{1};
dicom_info=get_dicom_info(fidic);
fid = fopen(fullfile(outdir,'acqp.txt'),'w');
for k = 1:length(dicom_info)
    h = dicom_info(k);
    hsession(k) = h.SeriesNumber;
    phase_angle = str2num(h.phase_angle);
    if isempty(phase_angle), phase_angle = 0;end
    switch h.PhaseEncodingDirection
        case 'COL '
            if phase_angle<0.1
                fprintf(fid,'0 -1 0 0.050\n');
            elseif abs(phase_angle-pi)<0.1
                fprintf(fid,'0 1 0 0.050\n');
            else
                error('what is the Y phase direciton <%f> in you  dicom!',phase_angle)
            end
        case 'ROW '
            if abs(phase_angle-pi/2)<0.1
                fprintf(fid,'-1 0 0 0.050\n');
            elseif abs(phase_angle+pi/2)<0.1
                fprintf(fid,'1 0 0 0.050\n');
            else
                error('what is the phase direciton in you fucking dicom!')
            end
            
        otherwise
            error('what is this phase axe <%s>', h.PhaseEncodingDirection)
    end
    
end

fclose(fid);
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

dim = read_dim_from_mosaic(h);
 if dim(3)==1
     error('pbr reading dim')
 end
 
 if mod(dim(3),2)==0 %even number of slice
     fprintf('even number of slice keeping --subsamp=2,2,2,2,2,1,1,1,1');
 elseif mod(dim(3),3)==0 
      fprintf('number of slice /3 so changing --subsamp=2,2,2,2,2,1,1,1,1  to --subsamp=3,3,3,3,3,1,1,1,1 ');
      cmd = sprintf('sed -i -e ''4s/.*/--subsamp=3,3,3,3,3,1,1,1,1/'' %s',fcnf{1});
      unix(cmd);
      
 else
     fprintf('what subsampling leven with %d slice?',dim(3))
     keyboard
 end
end

