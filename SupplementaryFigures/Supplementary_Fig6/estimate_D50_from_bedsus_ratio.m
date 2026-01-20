function D50_mm = estimate_D50_from_bedsus_ratio(target_ratio,u_star,h)
    % Constants
    g = 9.81;                   
    rho = 1000;                 
    rho_s = 2650;               
    s = rho_s / rho;            
    theta_cr = 0.047;           
    temp_C = 20;                
    nu = 1e-6 * (20 + temp_C) / 20;  
    
    % Assumed values
%     u_star = 0.1;               
%     h = 3.0;                    
    beta = 1.0;
    kappa = 0.4;
    f_alpha = 0.6;             
    
    % Objective function
    obj = @(D50) compute_error(D50, target_ratio, u_star, h, s, g, nu, theta_cr, beta, kappa, f_alpha);

    options = optimset('TolX', 1e-10, 'TolFun', 1e-14, 'MaxIter', 1e6, 'MaxFunEvals', 1e6);
    D50_guess = 0.001;  % 더 작은 grain size도 초기값으로 포함
    D50_m = fminsearch(obj, D50_guess);
    
    % Clamp result to physical bounds
    D50_m = max(min(D50_m, 0.05), 0.000010);  % 00 추가
    
    D50_mm = D50_m * 1000; 
end

function error = compute_error(D50, target_ratio, u_star, h, s, g, nu, theta_cr, beta, kappa, f_alpha)
    % Clamp to avoid non-physical values
    if D50 <= 0
        error = 1e6;
        return
    end

    D_star = D50 * ((s - 1) * g / nu^2)^(1/3);
    T = (u_star^2 / ((s - 1) * g * D50)) / theta_cr;

    % Bedload flux
    phi_bed = 0.1 * T^1.5 * D_star^-0.3;
    Q_bed = phi_bed * sqrt((s - 1) * g * D50^3);

    % Settling velocity
    ws = (nu / D50) * (sqrt(10.36^2 + D_star^3) - 10.36);

    % z_a and C_z
    z_a = min((20 * ws) / (beta * kappa * u_star), h);
    C_z = 0.015 * D50 * T^1.5 / (z_a * D_star^0.3);

    % Suspended load flux
    Q_sus = f_alpha * C_z * h * u_star;

    % 안전성 체크
    if Q_sus < 1e-10
        error = 1e6;
    else
        ratio = Q_bed / Q_sus;
        error = (ratio - target_ratio)^2;
    end
end
