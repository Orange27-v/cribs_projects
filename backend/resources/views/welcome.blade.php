<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Welcome to Cribs Arena</title>
</head>

<body
    style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background-color: #f6f8fa; line-height: 1.6;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; padding: 60px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0"
                    style="background-color: #ffffff; border: 1px solid #e1e4e8; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 40px 48px; border-bottom: 1px solid #e1e4e8; text-align: center;">
                            <img src="{{ asset('storage/logo/logo_light.png') }}" alt="Cribs Arena"
                                style="height: 60px; display: inline-block;" />
                        </td>
                    </tr>

                    <!-- Content -->
                    <tr>
                        <td style="padding: 48px;">
                            <h1 style="margin: 0 0 16px 0; font-size: 24px; font-weight: 700; color: #24292e; text-align: center;">
                                Experience the Future of Real Estate
                            </h1>

                            <p style="margin: 0 0 32px 0; font-size: 16px; color: #586069; text-align: center;">
                                Welcome to Cribs Arena. Your one-stop destination for modern property management, seamless rentals, and verified listings.
                            </p>

                            <!-- Call to Action -->
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td align="center" style="padding: 0 0 40px 0;">
                                        <a href="{{ url('/login') }}"
                                            style="background-color: #0066CC; color: #ffffff; padding: 14px 28px; border-radius: 6px; text-decoration: none; font-weight: 600; font-size: 16px; display: inline-block;">
                                            Get Started
                                        </a>
                                    </td>
                                </tr>
                            </table>

                            <!-- Features Grid -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="border-top: 1px solid #f0f1f2; padding-top: 32px;">
                                <tr>
                                    <td width="33%" style="padding: 0 8px; text-align: center; vertical-align: top;">
                                        <div style="font-size: 24px; margin-bottom: 8px;">🏠</div>
                                        <div style="font-size: 13px; font-weight: 600; color: #24292e; margin-bottom: 4px;">Verified Lists</div>
                                        <div style="font-size: 12px; color: #6a737d;">Only authentic properties</div>
                                    </td>
                                    <td width="33%" style="padding: 0 8px; text-align: center; vertical-align: top;">
                                        <div style="font-size: 24px; margin-bottom: 8px;">🤝</div>
                                        <div style="font-size: 13px; font-weight: 600; color: #24292e; margin-bottom: 4px;">Trusted Agents</div>
                                        <div style="font-size: 12px; color: #6a737d;">Vetted professionals only</div>
                                    </td>
                                    <td width="33%" style="padding: 0 8px; text-align: center; vertical-align: top;">
                                        <div style="font-size: 24px; margin-bottom: 8px;">💳</div>
                                        <div style="font-size: 13px; font-weight: 600; color: #24292e; margin-bottom: 4px;">Secure Pay</div>
                                        <div style="font-size: 12px; color: #6a737d;">End-to-end encryption</div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="padding: 32px 48px; border-top: 1px solid #e1e4e8; background-color: #f6f8fa; border-radius: 0 0 8px 8px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td>
                                        <p style="margin: 0; font-size: 12px; color: #6a737d; line-height: 1.5;">
                                            Cribs Arena<br>
                                            © {{ date('Y') }} All rights reserved.
                                        </p>
                                    </td>
                                    <td align="right">
                                        <div style="font-size: 12px;">
                                            <a href="#" style="color: #586069; text-decoration: none; margin-left: 12px;">Terms</a>
                                            <a href="#" style="color: #586069; text-decoration: none; margin-left: 12px;">Privacy</a>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
                <p style="margin-top: 24px; font-size: 12px; color: #959da5;">
                    Laravel v{{ Illuminate\Foundation\Application::VERSION }} (PHP v{{ PHP_VERSION }})
                </p>
            </td>
        </tr>
    </table>
</body>

</html>
