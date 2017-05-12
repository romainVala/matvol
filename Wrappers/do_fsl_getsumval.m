function sumall = do_fsl_getsumval(fin,textfile)
%output <voxels> <volume> (for nonzero voxels)

%f=cellstr(char(f));

if ~exist('textfile'), textfile='';end

for nbs=1:length(fin)
    
    f = cellstr(fin{nbs});
    
    for nbvol = 1:length(f)
        
        cmd = sprintf('fslstats %s -n -V',f{nbvol});
        [a,b]=unix(cmd);
        vol = str2num(b);
        
        cmd = sprintf('fslstats %s -n -M',f{nbvol});
        [a,b]=unix(cmd);
        volmean = str2num(b);
        
        sumal(nbvol) = vol(1)*volmean; %nombre de point * mean
        
    end
    sumall(nbs) = sum(sumal);
    
end


if ~isempty(textfile)
    
    filefid = fopen(textfile,'a+');
    fprintf(filefid,'\n\nPath,Volume,Mean volume');
    
    for nbs = 1:length(fin)
        f = cellstr(fin{nbs});

        for kk = 1:length(f)
            [pp ff] = fileparts(f{kk});
            
            if kk==1
                fprintf(filefid,'\n%s,',pp);
            end
            fprintf(filefid,'%s _ ',ff);
        
        end
        
        fprintf(filefid,',%f',sumall(nbs));
    end
    
    fclose(filefid);
end


