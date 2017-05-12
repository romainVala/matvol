function change_hdr_orientation(ff,P)
% ff is a cell of filepath(ff,P)
% P  the parameters for creating an affine transformation
% P(1)  - x translation
% P(2)  - y translation
% P(3)  - z translation
% P(4)  - x rotation about - {pitch} (radians)
% P(5)  - y rotation about - {roll}  (radians)
% P(6)  - z rotation about - {yaw}   (radians)
% P(7)  - x scaling
% P(8)  - y scaling
% P(9)  - z scaling
% P(10) - x affine
% P(11) - y affine
% P(12) - z affine
% default for mouse to be reoriented P = [0 0 0 pi/2 0 pi 1 1 1]


ff=cellstr(char(ff));


mat = spm_matrix(P);
if det(mat)<=0
    spm('alert!','This will flip the images',mfilename,0,1);
end

for k=1:length(ff)
    curent_mat = spm_get_space(ff{k});
    spm_get_space(ff{k},mat*curent_mat);
end


