function import_cenir_suj(spm_suj_dir,outdir,par)

if ~exist('par','var'),par ='';end
defpar.do_write=1;
defpar.concat_dti=0;
defpar.ser_regex='.*';


par = complet_struct(par,defpar);


for nbsuj = 1:length(spm_suj_dir)
    
    allDTI={};
    serdir = get_subdir_regex(spm_suj_dir(nbsuj),par.ser_regex)
    
    for nbser = 1:length(serdir)
        tdir = serdir{nbser};
        %dicom info hh from load dicfile
        dicfile=fullfile(tdir,'dicom_info.mat');
        if ~exist(dicfile,'file')
            warning('Skiping %s \nyou should re convert the dicom to get the dicom info .mat file',tdir)
            continue
        end
                
        load(dicfile); %this load the hh struct of dicom field
        
        if iscell(hh),    hh = hh{1}; end
        if is_dicom_series_type(hh,'derived')
            continue
        end
        
        
        ff = get_subdir_regex_images(tdir,'^f');
        
        if isempty(ff)
            is4D=0;
            ff = get_subdir_regex_images(tdir,'^s');
        else
            is4D=1;
        end
        
        seq_name = nettoie_dir([hh.SequenceSiemensName ]);
        
        [P  E S] = get_ExamDescription(hh);
        Eo = r_mkdir({outdir},E);    So = r_mkdir(Eo,S);
        
        %copy dicom info
        ffdic = get_subdir_regex_files(tdir,'dicom');
        r_movefile(ffdic,So,'copy');
        
        if is_dicom_series_type(hh,'dti')
            if par.concat_dti
                allDTI{end+1} = tdir;
                do_delete(So,0);
            else
                dti_import_multiple(tdir,So);
            end
            
        else
            if is4D
                do_delete(So,0);
                fprintf('\nSKIPING functional\n\n')
                continue
            else
                ffall = cellstr(char(ff)); %for phase map 2 files
                for nbf=1:length(ffall)
                    ff = ffall(nbf);
                    [pp fn] = get_parent_path(ff);
                    fn = change_file_extension(fn,'');
                    
                    fo = addsuffixtofilenames(So,'/');
                    fo = addsuffixtofilenames(fo,fn{1});
                    
                    do_fsl_chfiletype(ff,'NIFTI',fo);
                end
            end
        end
        
        if par.do_write
            text_par = fullfile(outdir,['param_' P '_' seq_name,'.csv']);
            write_dicom_info_to_csv({hh},text_par);
        end
        
    end
    if ~isempty(allDTI)       
        [pp dname]=get_parent_path(allDTI(1));
        dname=dname{1};dname(1:4)=''
        So = r_mkdir(Eo,sprintf('%s_DTI_concat%d',dname,length(allDTI)));
        dti_import_multiple(allDTI,So);
    end
end