<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Cribs Arena</title>
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
                                Welcome to Cribs Arena! We're excited to have you on board.
                            </p>

                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #586069;">
                                Your account has been successfully created. You can now:
                            </p>

                            <!-- Features List -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #e7f3ff; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span style="color: #0066CC; font-size: 12px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">Browse thousands of
                                                    properties across Nigeria</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #e7f3ff; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span style="color: #0066CC; font-size: 12px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">Book inspections with
                                                    verified agents</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #e7f3ff; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span style="color: #0066CC; font-size: 12px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">Save your favorite
                                                    properties</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px 0;">
                                        <table cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding-right: 12px; vertical-align: top;">
                                                    <div
                                                        style="width: 20px; height: 20px; background-color: #e7f3ff; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                                        <span style="color: #0066CC; font-size: 12px;">✓</span>
                                                    </div>
                                                </td>
                                                <td style="font-size: 14px; color: #586069;">Chat directly with property
                                                    agents</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                Start exploring properties in your area and find your perfect home today.
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