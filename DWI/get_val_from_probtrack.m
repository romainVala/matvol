function cout = get_val_from_probtrack(pdir,par,cout)

if ~exist('par'),  par='';end

if ~isfield(par,'name_prefix');  par.name_prefix = ''; end
if ~isfield(par,'name');  par.name = ''; end
if ~isfield(par,'name_change');  par.name_change = ''; end

name = par.name;

if isempty(name),guessname=1; else, guessname=0;end

if ~exist('cout')
    cout = struct;
end

for nbdir = 1:length(pdir)
    f_seed = get_subdir_regex_files(pdir(nbdir),'^seeds_to');f_seed=cellstr(char(f_seed));        
    f_wt = get_subdir_regex_files(pdir(nbdir),'waytotal',1);
    
    if guessname
        if nbdir==1
            if length(f_seed)==1
                [ppp name] = get_parent_path(f_seed);
                name = change_file_extension(name,'');
            else
                name = get_unique_name(f_seed,par.name_change);
            end
            %char(name)
        else
            nn = get_unique_name(f_seed,par.name_change);
%             if any(any(char(name)-char(nn)))
%                 printf('ARGGG')
%                 keyboard
%             end
        end
    end
    
    c(nbdir,:) = do_fsl_getsumval(f_seed);
    
    wtt = load(f_wt{1});
    wt(nbdir,:) = repmat(wtt,1,size(c,2));
    
    if isfield(par,'wm')        
        wmimages = cellstr(par.wm{nbdir});
                
        if isfield(par,'wm_scale'),scale=par.wm_scale;else scale=ones(1,length(wmimages));end

        for nbwm =1:length(wmimages)
            [FAimg,dimes,vox]=read_avw(wmimages{nbwm});
            for k=1:length(f_seed)
                [Conimg,dimes,vox]=read_avw(f_seed{k});
                Yw(nbdir,(nbwm-1)*length(f_seed)+k) = sum(FAimg(Conimg>0).*Conimg(Conimg>0))./sum(Conimg(Conimg>0)).*scale(nbwm);
            end
        end
    end
    
    if isfield(par,'thebiggest')
        if isempty(get_subdir_regex_files(pdir(nbdir),par.thebiggest))
            do_fsl_find_thebiggest({char(f_seed)});
        end
        bigf = get_subdir_regex_files(pdir(nbdir),par.thebiggest,1);
        [img,dimes,vox]=read_avw(bigf{1});
        for aa=1:length(f_seed)
            bigfsize(nbdir,aa) = length(find(img==aa))  * prod(vox(1:3));
        end
        bigfsize(nbdir,aa+1) = length(find(img>0))  * prod(vox(1:3));
    end
    
    
end

%c = c./wt*100;
%cout = setfield(cout,[par.name_prefix,'seed_vol'],sum(c,2));
for k=1:length(name)
    cout= setfield(cout,[par.name_prefix,'tot_con_',name{k}],c(:,k)');
end

cout = setfield(cout,[par.name_prefix,'wt'], wt(:,1)');

f_pt = get_subdir_regex_files(pdir,'^fdt_paths.nii',1);
sumfdt = do_fsl_getsumval(f_pt);

cout = setfield(cout,[par.name_prefix,'tot_fdt'], sumfdt./wt(:,1)'*100 );

if isfield(par,'wm')
    for nbwm =1:length(wmimages)
        for k=1:length(name)
            cout= setfield(cout,[par.name_prefix,'wm',par.wm_name{nbwm},'_',name{k}],Yw(:,(nbwm-1)*length(name)+k)');
        end
    end
end

if isfield(par,'thebiggest')
    for k=1:length(name)
        cout= setfield(cout,[par.name_prefix,'size_',name{k}],bigfsize(:,k)');
    end
    cout= setfield(cout,[par.name_prefix,'size_Seed'],bigfsize(:,end)');
    volseed = bigfsize(:,end)';
    for k=1:length(name)
        cout= setfield(cout,[par.name_prefix,'size_',name{k},'_Nvs'],bigfsize(:,k)'./volseed);
    end

end

function name = get_unique_name(aa,bb)

aa=char(aa);

first_ind = find(sum(diff(aa),1)); 
first_ind = first_ind(1);

for k =1:size(aa,1)
    na = deblank(aa(k,first_ind:end));
    ii = findstr(na,'.');
    the_name = na(1:ii(1)-1);
    indd = findstr(the_name,'-');
    the_name(indd)='m';
    name{k} = the_name;
end


if ~isempty(bb)
    for k=1:length(bb)
        for kk=1:length(name)
            if findstr(bb{k},name{kk})
                name{kk} = bb{k};
                break;
            end
            
        end
    end
end
