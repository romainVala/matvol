function r =count_mrtrix_track(vol,r,namefield)

if ~exist('namefield')
  namefield='';
end
if ~exist('r')
  r=struct;
end


for nbvol=1:size(vol{1},1)
  for k=1:length(vol)

    
    trk_hdr = read_mrtrix_tracks_hdr(deblank(vol{k}(nbvol,:)));

    if isempty(namefield)
      [p filename] = fileparts(vol{k}(nbvol,:));      
      field_name=['Nfibre_' nettoie_dir(filename) ];
      field_name2=['Nfibre_totcount' nettoie_dir(filename) ];
    else
      field_name  = namefield{nbvol};
    end
    
    r = setfield(r,field_name,{k},trk_hdr.count);
    r = setfield(r,field_name2,{k},trk_hdr.total_count);
    
  end
  
%  if k==1,  r = a; else r(k)=a;end
  
end
