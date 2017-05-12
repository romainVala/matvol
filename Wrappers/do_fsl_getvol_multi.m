function [vol ] = do_fsl_getvol_multi(f,par)
%function [vol varargout] = do_fsl_getvol(f,par)
%output <voxels> <volume> mean std Entropy 98 percentil (for nonzero voxels) or for
%voxel above the threshold seuil
if ~exist('par','var'),  par=''; end

defpar.lthr='';
defpar.uthr='';
defpar.abs=0;
defpar.mask='';
defpar.sujlevel=3;

par = complet_struct(par,defpar);


nbroi = size(f{1},1);

for nr = 1:nbroi
    for nbs=1:length(f)
        froi{nbs} = deblank(f{nbs}(nr,:));
    end
    
    if nr==1
        [pp ss]=get_parent_path(froi,par.sujlevel);
        
        cout.pool='volume';
        cout.suj = ss;
    end
    [pp roiname] = get_parent_path(froi(1));
    roiname=nettoie_dir(change_file_extension(roiname,''));
    
    vv = do_fsl_getvol(froi,par);
    cout = setfield(cout,roiname{1},vv(:,1));
    
end
vol=cout