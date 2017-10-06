function [Allsuj linename colname]  = read_freesurfer_seg_stat(file)

file=cellstr(char(file));

for nbf=1:length(file)
    af=file{nbf};
    [d r] = readtext(af,' *');
    
    ds = find(r.stringMask(:,1));
    last_comment=ds(end);
    colname = d(last_comment,3:end);
    % ColHeaders  Index SegId NVoxels Volume_mm3 StructName Mean StdDev Min Max Range
    
    d = d(last_comment+1:end,:);
    r.stringMask = r.stringMask(last_comment+1:end,:);
    r.numberMask = r.numberMask(last_comment+1:end,:);
    linename = d(r.stringMask);

    %replace nan by 0
    ii=find(r.stringMask(:));
    ind_rm=[];
    for kk=1:length(linename)
        if strfind(linename{kk},'nan')
            d{ii(kk)} = 0;
            r.numberMask(ii(kk))=1;
            ind_rm= [ind_rm kk];
        end
    end
    linename(ind_rm)=[];
    
    Mat = cell2mat( reshape(d(r.numberMask),[length(linename) length(colname)-1]) );
    [vv ii] = sort(Mat(:,1));
    linename=linename(ii);
    Mat=Mat(ii,:);
    m2=Mat(:,2); %Seg index
    if nbf>1
        if length(m2) ~= length(m1)
            ind_rm=[];
            for kk=1:length(m2)
                if ~any(m1==m2(kk))
                    ind_rm=[ind_rm kk];
                end
            end
            
            if ~isempty(ind_rm)
                fprintf('removing suj %s\n', linename{ind_rm});
                %keyboard
                m2(ind_rm) = [];
                Mat(ind_rm,:)=[];
            end
            
            ind_rm=[];
            for kk=1:length(m1)
                if ~any(m2==m1(kk))
                    ind_rm=[ind_rm kk];
                end
            end
            if ~isempty(ind_rm)
                fprintf('removing all because missing %s\n', linename{ind_rm});
                %keyboard
                Allsuj(ind_rm,:,:)=[];
                m1(ind_rm) = [];
                linename(ind_rm)=[];
            end
            
            
        end
        if any(m2~=m1)
            fprintf('qsdf');
            keyboard
        end
        
    else
        m1=Mat(:,2);
    end
    
    Allsuj(:,:,nbf) = Mat;
    
end

