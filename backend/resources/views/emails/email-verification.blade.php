<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify your email</title>
</head>

<body
    style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background-color: #f6f8fa; line-height: 1.6;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0"
                    style="background-color: #ffffff; border: 1px solid #e1e4e8; border-radius: 6px;">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 32px 40px; border-bottom: 1px solid #e1e4e8;">
                            <img src="{{ asset('storage/logo/logo_light.png') }}" alt="Cribs Arena"
                                style="height: 65px; display: block;" />
                        </td>
                    </tr>

                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #24292e;">Hi {{ $userName }},</p>

                            <p style="margin: 0 0 24px 0; font-size: 15px; color: #586069;">
                                Thank you for signing up! Please verify your email address to activate your account.
                            </p>

                            <!-- Code Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td
                                        style="background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 6px; padding: 24px; text-align: center;">
                                        <div
                                            style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: #586069; margin-bottom: 8px;">
                                            Verification code</div>
                                        <div
                                            style="font-size: 32px; font-weight: 600; color: #24292e; letter-spacing: 4px; font-family: 'Courier New', monospace;">
                                            {{ $verificationCode }}</div>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                Enter this code in the app to verify your email address.
                            </p>

                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                This code will expire in {{ $expiryMinutes }} minutes.
                            </p>

                            <p style="margin: 0 0 24px 0; font-size: 14px; color: #586069;">
                                If you didn't create an account, you can safely ignore this email.
                            </p>

                            <p style="margin: 0; font-size: 14px; color: #586069;">
                                Thanks,<br>
                                The Cribs Arena team
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="padding: 24px 40px; border-top: 1px solid #e1e4e8; background-color: #f6f8fa;">
                            <p style="margin: 0; font-size: 12px; color: #6a737d; line-height: 1.5;">
                                Cribs Arena<br>
                                © {{ date('Y') }} All rights reserved.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>

</html>