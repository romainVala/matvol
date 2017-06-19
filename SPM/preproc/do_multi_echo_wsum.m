function do_multi_echo_wsum(multi_dir,par)

if ~exist('par')
    par='';
end

defpar.subdir = 'echoWsum';
defpar.file_reg = '^f.*nii';
defpar.fsl_output_format='NIFTI';
defpar.te=[];
defpar.fsl_output_format='NIFTI';


par = complet_struct(par,defpar);


if iscell(multi_dir{1})
    nsuj = length(multi_dir);
else
    nsuj=1
end

cini = sprintf('export FSLOUTPUTTYPE=%s;',par.fsl_output_format);

for ns=1:nsuj
    
    curent_ff = get_subdir_regex_files(multi_dir{ns},par.file_reg);
    
    [suj sername] = get_parent_path(multi_dir{ns}(1))    ;
    sername = addsuffixtofilenames(sername,par.subdir);
    outdir = r_mkdir(suj,sername);
    
    for nbte = 1:length(curent_ff)
        ff = curent_ff(nbte);                

        [niftidir ffname] = get_parent_path(ff);
        fdic = get_subdir_regex_files(niftidir,'^dic.*json',1) ;
        
        if isempty(par.te) %try to find in json
            j=loadjson(fdic{k});
            for nbc=1:j.global.const.lContrasts
                fifi = sprintf('alTE_%d_',nbc-1);
                te(nbc) = getfield(j.global.const,fifi)./1000;
            end
            par.te = te;
        end
        
        %copy json file of the first echo only in the new dir for further use
        if nbte==1, r_movefile(fdic,outdir,'copy');,end
        
        f1=tempname;f2=tempname;
        cmd = sprintf('%s fslmaths %s -Tmean %s',cini,ff{1},f1);        unix(cmd);
        cmd = sprintf('%s fslmaths %s -Tstd %s',cini,ff{1},f2);        unix(cmd);
        fo = addprefixtofilenames(ff,'tSNR_');
        cmd = sprintf('%s fslmaths %s -div %s -mul %f -div 100 %s',cini,f1,f2,par.te(nbte),fo{1});
        unix(cmd);
        fadd{nbte} = tempname;
        cmd = sprintf('%s fslmaths %s -mul %s %s',cini,ff{1},fo{1},fadd{nbte});
        unix(cmd);
        
        if ~exist('cmdadd')
            cmdadd = sprintf('%s fslmaths %s ',cini,fadd{nbte});
        else
            cmdadd = sprintf('%s -add %s',cmdadd,fadd{nbte});
        end
                
    end
    
    [niftidir ffname] = get_parent_path(ff);
            
    fo = fullfile(outdir{1},addsuffixtofilenames(ffname{1},'_echoWsum'));
    cmdadd = sprintf('%s %s',cmdadd,fo);
    unix(cmdadd);
    clear cmdadd
end