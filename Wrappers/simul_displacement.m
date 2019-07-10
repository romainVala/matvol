function [fitpars,RMS_displacement,RMS_rot ] = simul_displacement(...
    nT,noiseBasePars,maxDisp,maxRot,...
    swallowFrequency,swallowMagnitude,suddenFrequency,suddenMagnitude,seed_num)


if seed_num
    rng(seed_num,'twister')
end


% general background noise movement:
fitpars = zeros(6,nT);

if  noiseBasePars
    fitpars(1,:) = maxDisp*(perlinNoise1D(nT,noiseBasePars).'-.5);
    fitpars(2,:) = maxDisp*(perlinNoise1D(nT,noiseBasePars).'-.5);
    fitpars(3,:) = maxDisp*(perlinNoise1D(nT,noiseBasePars).'-.5);
    
    fitpars(4,:) = maxRot*(perlinNoise1D(nT,noiseBasePars).'-.5);
    fitpars(5,:) = maxRot*(perlinNoise1D(nT,noiseBasePars).'-.5);
    fitpars(6,:) = maxRot*(perlinNoise1D(nT,noiseBasePars).'-.5);
end

% add in swallowing-like movements - just to z direction and pitch:
if swallowFrequency
    swallowTraceBase = exp(-linspace(0,1e2,nT));
    swallowTrace = zeros(1,nT);
    for iS = 1:swallowFrequency
        swallowTrace = swallowTrace + circshift(swallowTraceBase,[0 round(rand*nT)]);
    end
    fitpars(3,:) = fitpars(3,:) + swallowMagnitude(1)*swallowTrace;
    fitpars(4,:) = fitpars(4,:) + swallowMagnitude(2)*swallowTrace;
end

% add in random sudden movements in any direction:
if suddenFrequency
    suddenTrace = zeros(size(fitpars));
    for iS = 1:suddenFrequency
        iT_sudden = ceil(rand*nT);
        suddenTrace(:,iT_sudden:end) = bsxfun(@plus,suddenTrace(:,iT_sudden:end),[suddenMagnitude(1)*((2*rand(3,1))-1); suddenMagnitude(2)*((2*rand(3,1))-1)]);
    end
    fitpars = fitpars+suddenTrace;
end

fitpars = bsxfun(@minus,fitpars,fitpars(:,round(nT/2)));


displacements = sqrt(sum(fitpars(1:3,:).^2,1));
RMS_displacement = sqrt(mean(displacements.^2));

rotations = sqrt(sum(fitpars(4:6,:).^2,1));
RMS_rot   = sqrt(mean(rotations.^2));
