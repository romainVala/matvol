function plot( rpArray, maxFD )
% plots the realignment paramters for EPI sequences

if nargin < 2
    maxFD = 0.5; % mm
end

fcn_name = 'rp.plot';

for ex = 1 : size(rpArray,1)
    
    rp_in_exam = rpArray(ex,:).removeEmpty;
    
    rp = zeros(0,6);
    
    vbar_x    = zeros(2,length(rp_in_exam));
    vbar_y_TR =  ones(2,length(rp_in_exam));
    vbar_y_FD =  ones(2,length(rp_in_exam));
    vbar_y_FD(1,:) = 0;
    
    nVol = zeros(1,length(rp_in_exam));
    
    % Fetch rp data
    for ser = 1 : length(rp_in_exam)
        
        try
            rp_file = rp_in_exam(ser).path;
            current_rp = load(rp_file);
            if ser > 1
                rp = [ rp ; current_rp + ( rp(end,:) - current_rp(1,:) ) ]; %#ok<*AGROW>
            else
                rp = [ rp ; current_rp ];
            end
            
            vbar_x(:,ser) = size(rp,1) + 1 ;
            
            nVol(ser) = size(current_rp,1);
            
        catch
            % When volumes are not found
            warning('Could not find realignment paramters in %s ', rp_in_exam(ser).path )
            
        end
        
    end
    
    if size(rp,1) > 0
        
        % FD
        rHead  = 50; % mm
        drp    = diff(rp);
        drp    = [zeros(1,size(rp,2)); drp];
        FD     = sum(abs(drp(:,1:3)),2) + rHead*sum(abs(drp(:,4:6)),2);
        outlier = FD > maxFD;
        
        % Plot
        figure('Name',rp_in_exam(ser).exam.name,'NumberTitle','off')
        fprintf(    '[%s]: Plotting %s \n', fcn_name, rp_in_exam(ser).exam.name)
        fprintf(    '[%s]:     maxFD = %4.1f mm \n', fcn_name, maxFD)
        for ser = 1 : length(rp_in_exam)
            if ser ~= 1
                n_outliser = sum( outlier(vbar_x(1, ser-1) : (vbar_x(1, ser)-1)) );
            else
                n_outliser = sum( outlier(               1 : (vbar_x(1, ser)-1)) );
            end
            pct_outliser = round(100 * n_outliser/nVol(ser));
            fprintf('[%s]:     n_outlier = %4d/%4d  (%2d%%)  //   %s \n', fcn_name, n_outliser, nVol(ser), pct_outliser, rp_in_exam(ser).serie.name)
        end
        
        % translation
        subplot(3,1,1);
        hold on
        plot(rp(:,1:3))
        axis tight
        ylabel('translation in mm')
        xlabel('image')
        lim = ylim;
        plot(vbar_x, vbar_y_TR.*lim', 'black')
        legend({'x','y','z'},'location','best')
        
        % rotation
        subplot(3,1,2);
        hold on
        plot(rp(:,4:6)*180/pi)
        axis tight
        ylabel('rotation in °')
        xlabel('image')
        lim = ylim;
        plot(vbar_x, vbar_y_TR.*lim', 'black')
        legend({'pitch','roll','yaw'},'location','best')
        
        % FD
        subplot(3,1,3);
        hold on
        plot(FD)
        axis tight
        ylabel('FD (mm)')
        xlabel('image')
        lim = ylim;
        plot(ones(1,length(FD))*maxFD, ':red')
        plot(vbar_x, vbar_y_FD.*lim', 'black')
        legend({'FD', 'maxFD'},'location','best')
        
    end
    
end

end % function
