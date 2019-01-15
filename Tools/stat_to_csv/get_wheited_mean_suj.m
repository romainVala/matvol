function [cout] = get_wheited_mean_suj(fa,froi,par)

if ~exist('par'),par ='';end

defpar.faname = '';
defpar.faregex = '';
defpar.roiname = '';
defpar.roiregex = '';
defpar.fadir='';
defpar.roidir='';
defpar.seuil = 0;
defpar.skip_std=0;

par = complet_struct(par,defpar);


faname = par.faname;
faregex = par.faregex;
roiname = par.roiname;
roiregex = par.roiregex;
fadir = par.fadir;
roidir = par.roidir;

if isempty(faregex) %guess from volume name
   [ppfa faregex] = get_parent_path(fa(1));
   faregex = cellstr(char(faregex));
end

if isempty(faname) %guess from volume name
   faname = change_file_extension(faregex,'');
end

if isempty(roiregex) %guess from volume name
   [pproi roiregex] = get_parent_path(froi(1));
   roiregex = cellstr(char(roiregex));
end

if isempty(roiname) %guess from volume name
   roiname = change_file_extension(roiregex,'');
end

if isempty(fadir)
    [ppfa fff] = get_parent_path(fa);

    for kk=1:length(ppfa)
        ppfa{kk} = ppfa{kk}(1,:);
    end
    fadir = ppfa;
end

if isempty(roidir)
    [pproi fff] = get_parent_path(froi);

    for kk=1:length(pproi)
        pproi{kk} = pproi{kk}(1,:);
    end
    roidir=pproi;
end

cout = struct;
[pp sujn] = get_parent_path(fadir,2);
 cout.suj = sujn;
 cout.pool='ppp';


for kfa=1:length(faregex)
    %ffa = get_subdir_regex_files(fadir,['^' faregex{kfa}],1); %to do only if automaticaly define
    ffa = get_subdir_regex_files(fadir,[ faregex{kfa}],1);
    for kfp=1:length(roiregex)
        %ffroi = get_subdir_regex_files(roidir,['^' roiregex{kfp} '$'],1); %to do only if automaticaly define
        ffroi = get_subdir_regex_files(roidir,[ roiregex{kfp} ],1);
        [y ystd vol] = get_wheited_mean(ffa,ffroi,par);
        %marche pas sur l'oblique ??? cr = do_roistat(fprob,ffa,sujn);        y = cr.Mean_1;
        %vol = do_fsl_getvol(ffroi);vol = vol(:,2)'
                %if kfa>1; y = y*1000;end
        fi_name = nettoie_dir([change_file_extension(roiname{kfp},'') faname{kfa}]);
        fr_name = [ 'vol_' nettoie_dir([change_file_extension(roiname{kfp},'') ])];
        cout = setfield(cout,fr_name,vol)
        cout = setfield(cout,fi_name,y');
        if ~par.skip_std
            cout = setfield(cout,[fi_name 'std'],ystd./y');
        end
    end
end

