function [dKff, dKfu, dKuu, dKSigma] = ibpmultigpLowerBoundGradCovMat2(model)

% IBPMULTIGPLOWERBOUNDGRADCOVMAT

% IBPMULTIGP

%COPYRIGHT : Cristian Guarnizo, 2014

dKfu = cell(model.nout,model.nlf);
dKuu = cell(1,model.nlf);
dKSigma = zeros(1,model.nout);
dKff = cell(model.nout,model.nlf);
%dKff = zeros(model.nout,model.nlf);

EZS2 = model.etadq.*(model.varSdq + model.muSdq.^2);
EZdqSdq = model.etadq.*model.muSdq;
%Helpers to evaluate the gradient of Sigma_d (noise related matrix)
T1Sigmad = cell(model.nout,1);
T2Sigmad = cell(model.nout,1);
T5Sigmad = cell(model.nout,1);

for q = 1:model.nlf
    T1Kuu = 0;
    T3Kuu = 0;
    T4Kuu = 0;
    Euquq = (model.Kuuast{q} + model.Euast{q}*model.Euast{q}.');
    for d = 1:model.nout
        if q == 1
            T1Sigmad{d} = 0;
            T2Sigmad{d} = 0;
            T5Sigmad{d} = 0;
        end
        
        T1 = EZdqSdq(d,q)*model.beta(d)*model.m{d}*model.Euast{q}.';
        T1Kuu = T1Kuu + model.Kfu{d,q}.'*T1;
        
        k=1:model.nlf;
        k(q)=[];
        T2 = 0;
        for q1 = k
            T2 = T2 + EZdqSdq(d,q)*EZdqSdq(d,q1)...
                *model.Kfu{d,q1}*model.Kuuinv{q1}*model.Euast{q1}*model.Euast{q}.';
        end
        T2Sigmad{d} = T2Sigmad{d} + (model.Kuuinv{q}*model.Kfu{d,q}.')*(T2 + ...
            EZS2(d,q)*model.Kfu{d,q}*model.Kuuinv{q}*Euquq);
        
        T2 = model.beta(d)*T2;
        T3 = EZS2(d,q)*(model.beta(d)*model.Kfu{d,q})*(eye(size(Euquq,1)) - model.Kuuinv{q}*Euquq);
        dKfu{d,q} = (T1 - T2 + T3)*model.Kuuinv{q}; 
                       
        T3Kuu = T3Kuu + model.Kfu{d,q}.'*T2;
        T4Kuu = T4Kuu + EZS2(d,q)*model.beta(d)*model.Kfu{d,q}.'*model.Kfu{d,q};
        
        T1Sigmad{d} = T1Sigmad{d} + model.Kuuinv{q}*EZdqSdq(d,q)...
            *model.Kfu{d,q}.'*model.m{d}*model.Euast{q}.';
        %TODO check diag term
        T5Sigmad{d} = T5Sigmad{d} + EZS2(d,q)*(sum(model.Kff{d,q}) -...
           trace(model.Kfu{d,q}*model.Kuuinv{q}*model.Kfu{d,q}.'));
        
        if q == model.nlf
            dKSigma(d) = trace( T1Sigmad{d} - 0.5*T2Sigmad{d} ) - 0.5*sum(model.m{d}.^2)...
                - 0.5*T5Sigmad{d} + 0.5*model.sizeX(d)/model.beta(d);
        end
        
        dKff{d,q} = -0.5*EZS2(d,q)*model.beta(d)*eye(length(model.m{d}));
        %dKff(d,q) = -0.5*model.EZdqS2dq(d,q)*model.beta(d);
        
    end
    T4Kuu = Euquq*model.Kuuinv{q}*T4Kuu - T4Kuu + T4Kuu*model.Kuuinv{q}*Euquq;
    dKuu{q} = model.Kuuinv{q}*(-T1Kuu + 0.5*Euquq +T3Kuu + 0.5*T4Kuu)*model.Kuuinv{q} - 0.5*model.Kuuinv{q};
    dKuu{q} = triu(dKuu{q}) + triu(dKuu{q}.',1);
    dKuu{q} = dKuu{q} - triu(dKuu{q}',1)';
end

%dKSigma = sum(cell2mat(dKSigma'));