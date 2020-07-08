function job_rp_afni2spm(dfile, output_dir)
%
% INPUTS : 
% dfile = inputs directory
% output_dir = outputs directory 


for i = 1:length(dfile)
    rp_afni = load(dfile(i).name);
    
% Translation
Tx = rp_afni(:,4);
Ty = rp_afni(:,5);
Tz = rp_afni(:,6);

% Rotation : deg -> rad
Rx = rp_afni(:,1)*pi/180;
Ry = rp_afni(:,2)*pi/180;
Rz = rp_afni(:,3)*pi/180;

Datas=[Tx, Ty, Tz, Rx, Ry, Rz];

% file .txt
filename = fullfile(output_dir,sprintf('rp_spm.txt'));
    
save(filename,'Datas','-ascii','-double','-tabs')

end







