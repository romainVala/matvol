function [h, mr2vis]=mrtrix2trackvis(mrtrack,fafile,vistrack)

%% open mtrix file
mrtrix=read_mrtrix_tracks(mrtrack);
%% open fa associated image
Vmr       =spm_vol(fafile);
%[mrfa mrxyz]=spm_read_vols(Vmr);


%% get orientation info
% correct the spm matrix starting in (1,1,1) instead of (0,0,0)

% voxel size
vsize=sqrt(diag(Vmr.mat(1:3,1:3)'*Vmr.mat(1:3,1:3)))';

% voxel 2 mm matrix
vox2mm=Vmr.mat;
vox2mm(:,4)=Vmr.mat*[1;1;1;1];

matlabshift=zeros(4,4);
matlabshift(1:3,4)=[0.5 0.5 0.5];
mm2vox=vox2mm^-1+matlabshift;

%% orientation by letters
pad2=['LPS' char(0)] ;

[absv,absi]=max(abs(vox2mm),[],1);

ipaed=['LPS' char(0)] ;
posletters='RAS';
negletters='LPI';
for l=1:3
    if vox2mm(absi(l),l) >0
        ipad(l)=posletters(absi(l));
    else
        ipad(l)=negletters(absi(l));
    end
end
ipad

%% image orientation to patient (just guessing)
iop= [vox2mm(absi(1),1) vox2mm(absi(2),1) vox2mm(absi(3),1) ...
      vox2mm(absi(1),2) vox2mm(absi(2),2) vox2mm(absi(3),2)];
iop= - iop./[vsize vsize];
    

%% Tranform mm to voxel orientation
mr2vis={};
for i=1:size(mrtrix.data,2)
    % get mrtrix fiber
    fib=mrtrix.data{i}; 
    
    % fill trk structure
    mr2vis(i).nPoints=size(fib,1);
    %mr2vis(i).props=0; % don't know for what

    % apply the inverse matrix to get to the voxel milimetric space
    mr2vis(i).matrix=[];
    for f=1:size(fib,1)
        point=[fib(f,:)'; 1];

        vox=mm2vox*point;
        % lets transform all to lps to avoid problems
        % as mm space is RAS, we invert the two first componets
        %vox(1)=Vmr.dim(1)-vox(1);
        %vox(2)=Vmr.dim(2)-vox(2);
        %vox(1)=vox(1);
        %vox(2)=vox(2);
        mr2vis(i).matrix=[mr2vis(i).matrix; (vox(1:3)'.*vsize)];
    end
end

%% HEADER - hard coded orientation options
h.id_string=['TRACK' char(0)];
h.dim       =Vmr.dim;         % Image dimensions
h.voxel_size=vsize;  % Voxel dimensions
h.origin=[0 0 0]; % not used I think
h.n_scalars=0; % no scalar data (yet)
h.scalar_name = char(zeros(10,20));
h.n_properties = 0; % no properties (yet)
h.property_name =  char(zeros(10,20));
h.vox_to_ras =  vox2mm ;         % the qform
h.reserved =    char(zeros(444,1));
%h.voxel_order = ['LPS' char(0)]; % Always LPS?
h.voxel_order = [ipad char(0)];
% to change if oblique probably
h.pad2 =        pad2; %'RAS ';       % LAS/RAS when flip x
h.image_orientation_patient = iop; %-1 0 0 0 -1 0]; % 1(-1) 0 0 0 1(-1) 0 for flipped x
%
h.pad1 = [char(0) char(0)];
h.invert_x = 0;
h.invert_y = 0; % important?
h.invert_z = 0;
h.swap_xy = 0;
h.swap_yz = 0;
h.swap_zx = 0;
h.n_count=size(mrtrix.data,2);
h.version = 2;
h.hdr_size = 1000;
%% write track
trk_write(h,mr2vis,vistrack);
