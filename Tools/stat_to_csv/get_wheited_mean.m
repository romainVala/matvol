function [Y varargout] = get_wheited_mean(fa,fcon,par)

if ~exist('par'),par ='';end

defpar.seuil = 0;
defpar.mask = '';
defpar.omit = 0;

par = complet_struct(par,defpar);

seuil=par.seuil;

%at the subject level
fcon = cellstr(char(fcon));

Y = zeros(length(fa),length(seuil));

for i=1:length(fa)
    tt=zeros(1,length(seuil));
    %     [FAimg,dimes,vox]=read_avw(fa{i});
    %     for j=1:length(fcon)
    %         [Conimg,dimes,vox]=read_avw(fcon{j});
    %         Y(i,j) = sum(FAimg(Conimg>seuil).*Conimg(Conimg>seuil))./sum(Conimg(Conimg>seuil));
    %     end
    
    [FAimg,dimes,vox]=read_avw(fa{i});
    [Conimg,dimes,vox]=read_avw(fcon{i});
    if ~isempty(par.mask)
        [MASKimg,dimes,vox]=read_avw(par.mask{i});
        FAimg = FAimg(MASKimg>0);
        Conimg = Conimg(MASKimg>0);
    end

    %remove NaN
    FAimg(isnan(FAimg))=0;
    
    for kk =1:length(seuil)
         if par.omit
            tt(kk) = sum(FAimg(Conimg>seuil(kk)).*Conimg(Conimg>seuil(kk)),'omitnan')./sum(Conimg(Conimg>seuil(kk)),'omitnan');
        else
            tt(kk) = sum(FAimg(Conimg>seuil(kk)).*Conimg(Conimg>seuil(kk)))./sum(Conimg(Conimg>seuil(kk)));
        end
    end
    Y(i,:) = tt;
    if nargout>1
        Nw = length(Conimg(Conimg>seuil(1))>0)
        %fprintf('comput std\n')
        %Ystd(i) = std(FAimg(Conimg>seuil(1)));
        Ystd(i) =sqrt(sum(Conimg(Conimg>seuil(1)).*((FAimg(Conimg>seuil(1))-tt(1)).^2))/(sum(Conimg(Conimg>seuil(1))))*(Nw-1)/Nw)
       
    end
    if nargout>2
        %fprintf('comput std\n')
        aa = (Conimg>seuil(1));
        Vol(i) = sum(aa(:));
    end
end

if nargout>1
    varargout{1} = Ystd;
end

if nargout > 2
    varargout{2} = Vol;
end


