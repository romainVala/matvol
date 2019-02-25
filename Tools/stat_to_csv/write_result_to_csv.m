
function write_result_to_csv(conc,resname,field_list)

if ~exist('field_list')
    field_list = fieldnames(conc);
end


fid = fopen(resname,'a+');
nbline=0;
while fgetl(fid)~=-1
    nbline=nbline+1;
end


for npool = 1:length(conc)
    
    
    if strcmp(field_list{1},'pool')
        field_list = field_list(2:end);
        fprintf(fid,'%s\n',conc(npool).pool);
    end
    
    f1 = getfield(conc(npool),field_list{1});
    
    if iscell(f1)
        nbsuj = length(f1);
    else
        nbsuj=length(f1);%no more 1
    end 
    
    
    for nbs = 1:nbsuj
        
        if nbs==1 % mod(nbline,40)==0
            %print the header
            for kn = 1:length(field_list)
                fprintf(fid,'%s,',field_list{kn});
            end
            fprintf(fid,'\n');
        end
        nbline = nbline+1;
        
        for kn = 1:length(field_list)
            aa = getfield(conc(npool),field_list{kn});
            if iscell(aa)
                if isnumeric(aa{nbs})
                    val = num2str(aa{nbs});
                else
                    val = aa{nbs};
                end
                fprintf(fid,'%s,',val);
            elseif isstruct(aa)
            elseif isempty(aa)
                fprintf(fid,',');
            else
                if isnumeric(aa)
                    fprintf(fid,'%f,',aa(nbs));
                else
                    fprintf(fid,'%s,',aa);
                end                   
            end
        end
        fprintf(fid,'\n');
    end
    
    
end


fclose(fid);
