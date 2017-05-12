function suj = r_copy_suj(suj,outputdir,par)
%suj = r_moverfile(suj,outputdir,par)
%for a list of subject in d copy in outputdir
%
if ~exist('par','var'),par ='';end

defpar.serreg = '^S';
defpar.filereg = '.*';


par = complet_struct(par,defpar);

for nbs=1:length(suj)
    
    ser = get_subdir_regex(suj(nbs),par.serreg);
    files = get_subdir_regex_files(ser,par.filereg);
    
    [p sujname ] = get_parent_path(suj(nbs));
    [p sername] = get_parent_path(ser);
    
    sujout(nbs) = r_mkdir(outputdir,sujname);
    serout = r_mkdir(sujout{nbs} ,sername)
    
    r_movefile(files,serout,'link');
    
    for kk=1:length(ser)
        subdir = get_subdir_regex(ser(kk),'.*');
        if ~isempty(subdir)
            pp.serreg='.*';
            r_copy_suj(ser(kk),sujout{nbs},pp);
            
        end
    end
end

