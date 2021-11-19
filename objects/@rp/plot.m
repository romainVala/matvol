function plot( rpArray )
% plots the realignment paramters for EPI sequences

for ex = 1 : size(rpArray,1)
    
    rp_in_exam = rpArray(ex,:).removeEmpty;
    
    rp = zeros(0,6);
    
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
            
        catch
            % When volumes are not found
            warning('Could not find realignment paramters in %s ', rp_in_exam(ser).path )
            
        end
        
    end
    
    if size(rp,1) > 0
        
        % Plot
        figure('Name',rp_in_exam(ser).exam.name,'NumberTitle','off')
        fprintf(    '[plotRealign]: Plotting %s \n', rp_in_exam(ser).exam.name)
        for ser = 1 : length(rp_in_exam)
            fprintf('[plotRealign]:          %s \n', rp_in_exam(ser).name)
        end
        
        % translation
        subplot(3,1,1);
        plot(rp(:,1:3))
        axis tight
        ylabel('translation in mm')
        xlabel('image')
        legend('x','y','z','location','best')
        
        % rotation
        subplot(3,1,2);
        plot(rp(:,4:6)*180/pi)
        axis tight
        ylabel('rotation in °')
        xlabel('image')
        legend('pitch','roll','yaw','location','best')
        
        % FD
        subplot(3,1,3);
        rHead  = 50; % mm
        drp    = diff(rp);
        drp_mm = [drp(:,1:3) drp(:,4:6)*pi/360*rHead];
        FD     = sum(abs(drp_mm),2);
        plot(FD)
        axis tight
        ylabel('FD (mm)')
        xlabel('image')
        
    end
    
end

end % function
