function t = concat_freesurfer_stats(fin,fout)

for k=1:length(fin)
    
    [a b] = readtext(fin{k},' +');
    
    %find the last commented ligne
    nbline=1;
    while strcmp(a{nbline,1},'#')
        nbline=nbline+1;
    end
    
    colname = a(nbline-1,2:end); colname{1} ='';
    
    for nbl = nbline:size(a,1)
        
        line = a(nbl,:);
        if isempty(line{1}); 
            line(1)=''; line{end+1}=0;
            a(nbl,:)=line;
        end   % first number start with a space
    
    end
    
    if k==1
        segname = a(nbline:end,5);
        segid1   = cell2mat (a(nbline:end,2));
        
        [segid1 indsort] = sort (segid1);
        
        segvol  = cell2mat (a(nbline:end,4));
        segmean = cell2mat (a(nbline:end,6));
        segstd  = cell2mat (a(nbline:end,7));
        
        segvols = segvol(indsort);    segmeans = segmean(indsort);    segstds = segstd(indsort);
        
        
    else
        segid   = cell2mat (a(nbline:end,2));
        [segid indsort] = sort (segid);
        if any(segid-segid1), error('different segmentations ids ... TODO '); end

        segvol  = cell2mat (a(nbline:end,4));
        segmean = cell2mat (a(nbline:end,6));
        segstd  = cell2mat (a(nbline:end,7));
        
        segvols  = [segvols , segvol(indsort)];    
        segmeans = [segmeans, segmean(indsort)];    
        segstds  = [segstds, segstd(indsort)];
                
    end
end
[~, sujn] = get_parent_path(fin,3);

%remove empty labels
ii=sum(segvols>0,2);
ii = find(ii==0)
segid(ii,:)=[];  segname(ii) = []; segvols(ii,:)=[]; segmeans(ii,:) = []; segstds(ii,:)=[];

%construct big table 
c1 = strrep(addprefixtofilenames(segname,'Vol_'),'-','_');
c2 = strrep(addprefixtofilenames(segname,'Mean_'),'-','_');
c3 = strrep(addprefixtofilenames(segname,'std_'),'-','_');

tt = [segvols; segmeans; segstds]';
cc=[c1;c2;c3]';
t=array2table(tt, 'VariableNames',cc,'RowNames',sujn);

if exist('fout','var')
    writetable(t,fout,'WriteRowNames',1)
end


%     
%     
% [~, sujn] = get_parent_path(fin,3)
% 
%     cmd = 'source freesurfer6; merge_stats_tables  --meas=Mean  --tablefile=toto.csv '
% %     for k=1:length(sujn)
% %         cmd = sprintf('%s %s ', cmd, sujn{k});
% %     end
%     
% for k=1:length(fin)
%  cmd = sprintf('%s -i %s',cmd,fin{k});
% end
% 
% [a b ] = unix(cmd)
% 
% par.jobname='merge_stat'
% par.sge=1
% do_cmd_sge({cmd},par)
