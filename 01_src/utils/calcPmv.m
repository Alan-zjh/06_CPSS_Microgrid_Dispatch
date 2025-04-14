%================================================================
% 功能：  计算 PMV 值
% 参数：  ta  - 空气温度 (°C)
%         tr  - 平均辐射温度 (°C)
%         va  - 风速 (m/s)
%         th  - 相对湿度 (%)
%         met - 代谢率 (MET)
%         clo - 服装热阻 (CLO)
%         wme - 机械做工，默认0 
% 返回值： PMV数值
% 主要思路： PMV 热平衡方程
% 备注：   无
% 调用方法： 直接调用
% 日期：   2025/2/28 13:55
%================================================================
function pmv = calcPmv(ta, tr, vel, rh, met, clo, wme)
    % 默认 wme（外部功率）为 0，如果未提供
    if nargin < 7
        wme = 0;
    end
    if met > 1
        vel = vel + 0.3 * (met - 1);
    end
    
    % if met > 1.2
    %     clo = clo * (0.6 + 0.4 / met);
    % end
    % ce = cooling_effect(ta,tr,vel,rh,met,clo,wme);
    % if ce ~= 0 && vel > 0.1
    %     ta = ta - ce;
    %     tr = tr - ce;
    %     vel = 0.1;
    % end
    % 计算水蒸气分压力 (Pa)
    pa = rh * 10 * exp(16.6536 - 4030.183 / (ta + 235));
        
    % 将代谢率和外部功率转换为 W/m²
    m = met * 58.15;
    w = wme * 58.15;
    mw = m - w; % 人体内部产热量
    
    % 将服装热阻 (clo) 转换为热阻 (m2K/W)
    icl = 0.155 * clo;

    % 计算服装因子 fcl
    if icl <= 0.078
        fcl = 1 + 1.29 * icl;
    else
        fcl = 1.05 + 0.645 * icl;
    end
    
    % 计算强制对流换热系数
    hcf = 12.1 * sqrt(vel);
    taa = ta + 273; % 绝对空气温度 (K)
    tra = tr + 273; % 绝对辐射温度 (K)
    t_cla = taa + (35.5 - ta) / (3.5 * icl + 0.1); % 初始衣服表面温度 (K)
    
    % 计算中间变量
    p1 = icl * fcl;
    p2 = p1 * 3.96;
    p3 = p1 * 100;
    p4 = p1 * taa;
    p5 = 308.7 - 0.028 * mw + p2 * (tra / 100)^4;
    
    xn = t_cla / 100;
    xf = t_cla / 50;
    eps = 0.00015; % 迭代精度
    n = 0;
    
    % 计算衣服表面温度 tcl
    while abs(xn - xf) > eps
        xf = (xf + xn) / 2;
        hcn = 2.38 * abs(100 * xf - taa)^0.25;
        hc = max(hcf, hcn); % 取较大的换热系数
        xn = (p5 + p4 * hc - p2 * xn^4) / (100 + p3 * hc);
        n = n + 1;
        if n > 150
            error('最大迭代次数超限');
        end
    end
    
    tcl = 100 * xn - 273; % 计算最终衣服表面温度 (°C)
    
    % 计算人体各部分的热量损失
    hl1 = 3.05 * 0.001 * (5733 - 6.99 * mw - pa); % 皮肤水分扩散损失
    hl2 = max(0, 0.42 * (mw - 58.15)); % 出汗热损失
    hl3 = 1.7 * 0.00001 * m * (5867 - pa); % 潜热呼吸热损失
    hl4 = 0.0014 * m * (34 - ta); % 干燥呼吸热损失
    hl5 = 3.96 * fcl * (xn^4 - (tra / 100)^4); % 辐射热损失
    hl6 = fcl * hc * (tcl - ta); % 对流热损失
    
    % 计算 PMV（预测平均投票）
    ts = 0.303 * exp(-0.036 * m) + 0.028;
    pmv = ts * (mw - hl1 - hl2 - hl3 - hl4 - hl5 - hl6);
    
    % 计算 PPD（预测不满意率）
    % ppd = 100 - 95 * exp(-0.03353 * pmv^4 - 0.2179 * pmv^2);
    
end

% function result = pierceSET(ta, tr, vel, rh, met, clo, wme, round_flag, calculateCE, maxSkinBloodFlow, bodyPosition)
%     % 参数默认值处理
%     if nargin < 7, wme = 0; end
%     if nargin < 8, round_flag = false; end
%     if nargin < 9, calculateCE = false; end
%     if nargin < 10, maxSkinBloodFlow = 90; end
%     if nargin < 11, bodyPosition = 'sitting'; end
% 
%     % 常量定义
%     SBC = 5.6697e-8; % Stefan-Boltzmann常数 (W/m²K⁴)
%     CSW = 170;
%     CDil = 120;
%     CStr = 0.5;
%     TempSkinNeutral = 33.7;   % 中性皮肤温度
%     TempCoreNeutral = 36.8;   % 中性核心温度
%     TempBodyNeutral = 36.49;  % 中性体核温度
%     SkinBloodFlowNeutral = 6.3; % 中性皮肤血流量
%     KClo = 0.25;
%     BodyWeight = 69.9;        % 体重 (kg)
%     BodySurfaceArea = 1.8258; % 体表面积 (m²)
%     MetFactor = 58.2;         % 代谢率转换系数
%     LTime = 60;               % 迭代时间
% 
%     % 中间变量初始化
%     [VaporPressure, AirSpeed, p] = initialize_vars(ta, rh, vel);
%     [heatTransferConvMet, CHC, CHR, RCl, FACL, LR, RM, M] = setup_params(met, vel, clo, calculateCE, p);
% 
%     % 迭代求解过程
%     [TempSkin, TempCore, SkinBloodFlow, ALFA, ESK, TCL, ExcBloodFlow, ExcRegulatorySweating, ExcCriticalWettedness] = ...
%         main_iteration_loop(ta, tr, bodyPosition, LTime, TempSkinNeutral, TempCoreNeutral, ...
%         SkinBloodFlowNeutral, maxSkinBloodFlow, SBC, CHC, CHR, FACL, RCl, M, wme, BodySurfaceArea, ...
%         BodyWeight, CSW, CDil, CStr, VaporPressure, MetFactor);
% 
%     % 计算最终结果参数
%     [result, HSK, W, PSSK] = calculate_results(ta, tr, vel, met, wme, round_flag, calculateCE, ...
%         TempSkin, TempCore, TCL, SkinBloodFlow, ALFA, p, SBC, KClo, VaporPressure, ...
%         ExcBloodFlow, ExcRegulatorySweating, ExcCriticalWettedness, HSK, W, PSSK);
% 
%     % 结果舍入处理
%     if round_flag
%         result.set = round(result.set, 1);
%     end
%     end
% 
%     function [VaporPressure, AirSpeed, p] = initialize_vars(ta, rh, vel)
%     % 计算水蒸气压力
%     VaporPressure = rh * FindSaturatedVaporPressureTorr(ta) / 100;
%     AirSpeed = max(vel, 0.1);           % 风速下限处理
%     p = psyPROP();                     % 获取大气压属性
%     end
% 
%     function [heatTransferConvMet, CHC, CHR, RCl, FACL, LR, RM, M] = setup_params(met, vel, clo, calculateCE, p)
%     % 计算对流换热系数
%     heatTransferConvMet = 3.0 + 2.56*(met >= 0.85).*(met - 0.85).^0.39;
%     PressureInAtmospheres = p * 0.009869;
% 
%     % 计算CHC值
%     CHC_base = 3.0 * PressureInAtmospheres^0.53;
%     CHCV = 8.600001 * (AirSpeed * PressureInAtmospheres)^0.53;
%     CHC = max([CHC_base, CHCV]);
%     if ~calculateCE
%         CHC = max([CHC, heatTransferConvMet]);
%     end
% 
%     % 服装热阻计算
%     RCl = 0.155 * clo;
%     FACL = 1.0 + 0.15 * clo;       % 服装面积系数
%     LR = 2.2 / PressureInAtmospheres; % Lewis关系系数
%     RM = met * MetFactor;
%     M = RM;
% end
% 
% function [TempSkin, TempCore, SkinBloodFlow, ALFA, ESK, TCL, ExcBloodFlow, ExcRegulatorySweating, ExcCriticalWettedness] = ...
%     main_iteration_loop(ta, tr, bodyPosition, LTime, TempSkinNeutral, TempCoreNeutral, ...
%     SkinBloodFlowNeutral, maxSkinBloodFlow, SBC, CHC, CHR, FACL, RCl, M, wme, BodySurfaceArea, ...
%     BodyWeight, CSW, CDil, CStr, VaporPressure, MetFactor)
% 
%     % 初始化生理参数
%     TempSkin = TempSkinNeutral;
%     TempCore = TempCoreNeutral;
%     SkinBloodFlow = SkinBloodFlowNeutral;
%     ALFA = 0.1;
%     ESK = 0.1 * met;
% 
%     % 主迭代循环
%     for TIM = 1:LTime
%         % 服装表面温度迭代
%         [TCL, CHR, CTC, RA, TOP] = update_clothing_temp(TCL, bodyPosition, tr, SBC, CHC, FACL, RCl, TempSkin);
% 
%         % 计算热平衡参数
%         [DRY, HFCS, ERES, CRES, SCR, SSK, TCSK, TCCR, DTSK, DTCR] = ...
%             calculate_heat_balance(M, TempCore, TempSkin, SkinBloodFlow, VaporPressure, ta, wme, ...
%             BodySurfaceArea, BodyWeight, RA, RCl, TOP, ESK);
% 
%         % 更新生理参数
%         [TempSkin, TempCore, TB, SKSIG, WARMS, COLDS, CRSIG, WARMC, COLDC, BDSIG, WARMB] = ...
%             update_body_temps(TempSkin, DTSK, TempCore, DTCR, ALFA);
% 
%         % 调节机制计算
%         [SkinBloodFlow, ExcBloodFlow, REGSW, ExcRegulatorySweating, ERSW, EMAX, PRSW, PWET, EDIF, ExcCriticalWettedness] = ...
%             thermoregulation_mechanisms(SkinBloodFlowNeutral, CDil, WARMC, CStr, COLDS, maxSkinBloodFlow, ...
%             CSW, WARMB, WARMS, VaporPressure, TempSkin, LR, FACL, CHC, RCl);
% 
%         % 更新代谢参数
%         [M, MSHIV, ALFA] = update_metabolism(met, MetFactor, COLDS, COLDC, SkinBloodFlow);
%     end
% 
%     % 计算最终皮肤热损失
%     HSK = DRY + ESK;
% end
% 
% function result = psyPROP()
%     % 大气压力属性（示例值，需要根据实际情况调整）
%     result.Patm = 101325; % 标准大气压 (Pa)
% end
% 
% function p = FindSaturatedVaporPressureTorr(T)
%     % 计算饱和水汽压（Torr），使用Antoine方程
%     T_kelvin = T + 273.15;
%     p = exp(18.6686 - 4030.183/(T_kelvin + 235)); % 示例公式，可能需要根据ASHRAE标准调整
% end
% 
% 
% 
% function ce = cooling_effect(ta, tr, vel, rh, met, clo, wme, bodyPosition)
%     if nargin < 8
%         bodyPosition = "standing";
%     end
% 
%     ce_l = 0;
%     ce_r = 40;
%     eps = 0.001; % precision of ce
% 
%     if vel <= 0.1
%         ce = 0;
%         return;
%     end
% 
%     set = pierceSET(ta, tr, vel, rh, met, clo, wme, false, true, 90, bodyPosition).set;
% 
%     fn = @(ce_val) set - pierceSET(ta - ce_val, tr - ce_val, 0.1, rh, met, clo, wme, false, true, 90, bodyPosition).set;
% 
%     ce = secant(ce_l, ce_r, fn, eps);
% 
%     if isnan(ce)
%         ce = bisect(ce_l, ce_r, fn, eps, 0);
%     end
% 
%     if ce < 0
%         ce = 0;
%     end
% end
% 
% function result = secant(a, b, fn, epsilon)
%     f1 = fn(a);
%     if abs(f1) <= epsilon
%         result = a;
%         return;
%     end
%     f2 = fn(b);
%     if abs(f2) <= epsilon
%         result = b;
%         return;
%     end
% 
%     for i = 1:100
%         slope = (f2 - f1) / (b - a);
%         c = b - f2 / slope;
%         f3 = fn(c);
% 
%         if abs(f3) < epsilon
%             result = c;
%             return;
%         end
% 
%         a = b;
%         b = c;
%         f1 = f2;
%         f2 = f3;
%     end
%     result = NaN;
% end
% 
% function result = bisect(a, b, fn, epsilon, target)
%     while abs(b - a) > 2 * epsilon
%         midpoint = (b + a) / 2;
%         a_T = fn(a);
%         b_T = fn(b);
%         midpoint_T = fn(midpoint);
% 
%         if (a_T - target) * (midpoint_T - target) < 0
%             b = midpoint;
%         elseif (b_T - target) * (midpoint_T - target) < 0
%             a = midpoint;
%         else
%             result = -999;
%             return;
%         end
%     end
%     result = midpoint;
% end
% 
