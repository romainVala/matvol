function cout = calc_AES(fin,par)

if ~exist('par','var'),par ='';end
defpar.mask='';

par = complet_struct(par,defpar);

fin=cellstr(char(fin));

norme_type = {'Vol','Slice','None'};

for n=1:length(fin)
    clear v
    is_mask=0;
    [v, Vol]=nifti_spm_vol(fin{n});
    if ~isempty(par.mask)
        [vv, Volmask ] = nifti_spm_vol(par.mask{n});
        Vol(Volmask==0) = 0;
        is_mask=1;
    end
    
    %normalize image intensity between the 5th and 95th percentile
    scal=(Vol-prctile(Vol(Vol>0),5))/(prctile(Vol(Vol>0),95)-prctile(Vol(Vol>0),5));
    Vol_norm=sign(Vol).*max(0.05,scal);
    Vol_norm=min(0.95,Vol_norm);
    
    %
    a=[-1 -1 -1; 0 0 0; 1 1 1];
    b=[-1 0 1; -1 0 1; -1 0 1];
    
    for nb_norm=1:length(norme_type)
        aes_sl=zeros(size(Vol_norm,3),1);
        aes_edge_sl=zeros(size(Vol_norm,3),1);
        for z=1:size(Vol_norm,3)
            %if z==196, keyboard;end
            switch norme_type{nb_norm}
                case 'None'
                    c = Vol(:,:,z);
                case 'Vol'
                    c=Vol_norm(:,:,z);
                case 'Slice'
                    c = Vol(:,:,z);
                    scal=(c-prctile(c(c>0),5))/(prctile(c(c>0),95)-prctile(c(c>0),5));
                    c_norm=sign(c).*max(0.05,scal);
                    c=min(0.95,c_norm);
            end
            
            %computes the 2D gradient image slice by slice
            gradx=conv2(double(c),double(a));
            grady=conv2(double(c),double(b));
            gradx1=gradx(2:size(gradx,1)-1,2:size(gradx,2)-1);
            grady1=grady(2:size(grady,1)-1,2:size(grady,2)-1);            
            
            gradmag=gradx1.^2+grady1.^2;
                        
            %calculate a binary mask of edges using the Canny edge detector
            edges=edge(c,'canny');
            
            if is_mask
                c_mask = Volmask(:,:,z);
                edges = edges.*c_mask; %with smooth edge go  beyong mask
                
            end
            
            %AES computation according to Aksoy et al. MRM 2012:67:1237
            edgeval=edges.*gradmag;
            aes_nom=sum(edgeval(:));
            
            denom=size(edges(edges>0),1);
            aes_edge_sl(z,1) = denom;
            if (denom~=0)
                
                aes_sl(z,1)=sqrt(aes_nom)/denom;
                %aes_sl(z,1)=(aes_nom)/denom;
            else
                aes_sl(z,1)=0;
            end
        end
        %Calculate AES 90th percentile
        aes_m=aes_sl(aes_sl>0);
        aes=prctile(aes_m,90);
        %aes_sl = [aes ; aes_sl];

        fname = sprintf('aes_sl_%s',norme_type{nb_norm});cout.(fname) = aes_sl;
        fname = sprintf('aes_edge_%s',norme_type{nb_norm});cout.(fname) = aes_edge_sl;
        
        %cout.aes_sl = aes_sl;
        %cout.aes_prc = aes;
    end
end


