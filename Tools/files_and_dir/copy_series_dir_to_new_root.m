function do = copy_series_dir_to_new_root(serin,rootdir)


[pp,prot,exa,ser] = get_parent_path(serin,3);

for nbs=1:length(ser)
    newser = fullfile(rootdir,prot{nbs},exa{nbs},ser{nbs});
    if ~exist(newser,'file')
        mkdir(newser) ;
        ffo = get_subdir_regex_files(serin{nbs},'.*');
        r_movefile(ffo,newser,'link');
    end
    do{nbs}=newser;
end
