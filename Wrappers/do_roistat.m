function cout = do_roistat(flabel,fa,par,cin)

if ~exist('par'),par ='';end

defpar.sujname = 'todo';
defpar.label_name = '';
defpar.label_orig_name = '';
defpar.checkdate = 0;

defpar.sge=0;
defpar.jobname = 'roistat';
defpar.walltime = '00:10:00';

par = complet_struct(par,defpar);

sujname = par.sujname;

[do faname] = get_parent_path(fa);
faname = change_file_extension(faname,'');

[pp flabelname ] = get_parent_path(flabel);
flabelname = nettoie_dir(flabelname);

if exist('cin','var')
    cout=cin;
end

cmds={};
for nbs=1:length(flabel)
    
    files_save = fullfile(do{nbs}, [faname{nbs} '_statsOn_' flabelname{nbs} '.csv']);
    
    
    if exist(files_save,'file')
        doit=0;
        if par.checkdate
            d1=dir(fa{nbs});d2=dir(flabel{nbs});        d=dir(files_save);
            if d2.datenum>d.datenum || d1.datenum>d.datenum
                doit=1;
                %load files_save
            end
        end
    else
        doit=1;
    end
    
    if doit
        cmd = sprintf('3dROIstats -mask %s %s > %s',flabel{nbs},fa{nbs},files_save);
        unix(cmd);
    end
    
    [a r]=readtext(files_save,'\t');
    hdr = a(1,3:end);
    val = cell2mat(a(2,3:end));
    
    if nbs==1
        hdrref=hdr;
        cout.pool = faname{nbs};
    else
        if length(hdr)~=length(hdrref)
            %if hdr is bigger
            for kk=1:length(hdr)
                for jj=1:length(hdrref)
                    if strcmp(hdr{kk},hdrref{jj})
                        found(kk)=1;
                        break
                    end
                end
            end
            iind = find(found==0)
            fprintf('skiping %d label %s for suj\n label %s \n ',length(iind),flabel{nbs},hdr{iind(1)})
            hdr(find(found==0))='';
            val(find(found==0))='';
        end
        
        if any(any(char(hdr)-char(hdrref)))
            error('not the same label')
        end
        
    end
    
    Vals(nbs,:) = val;
    
end


cout.suj = sujname;

for nh = 1:length(hdr)
    if ischar(par.label_name )
        if strcmp(par.label_name , 'freesurfer')
            flabel = find_free_label_name({str2num(hdr{nh}(6:end))}) ;
            flabel =   nettoie_dir (flabel{1});
            if ~isempty(str2num(flabel(1)))
                flabel = ['s' flabel];
            end
        elseif ~isempty(par.label_name)
                flabel = par.label_name;
        else
            flabel = hdr{nh};
        end
        
    end
    cout = setfield(cout,flabel,Vals(:,nh));
        
end

