<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Withdrawal Initiated</title>
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
                                style="height: 55px; display: block;" />
                        </td>
                    </tr>

                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #24292e;">Hi
                                {{ $withdrawalData['userName'] }},</p>

                            <p style="margin: 0 0 8px 0; font-size: 15px; color: #586069;">
                                You have successfully initiated a withdrawal from your wallet.
                            </p>

                            <!-- Status Badge -->
                            <table cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td
                                        style="background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 3px; padding: 4px 12px;">
                                        <span
                                            style="font-size: 11px; font-weight: 600; color: #586069; text-transform: uppercase; letter-spacing: 0.5px;">Withdrawal
                                            Processing</span>
                                    </td>
                                </tr>
                            </table>

                            <!-- Amount Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td
                                        style="background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 6px; padding: 24px; text-align: center;">
                                        <div
                                            style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: #586069; margin-bottom: 8px;">
                                            Net Amount to Receive</div>
                                        <div style="font-size: 32px; font-weight: 600; color: #24292e;">
                                            ₦{{ number_format($withdrawalData['netAmount'], 2) }}</div>
                                    </td>
                                </tr>
                            </table>

                            <!-- Withdrawal Details -->
                            <table width="100%" cellpadding="0" cellspacing="0"
                                style="margin: 0 0 24px 0; background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 6px;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <table width="100%" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Withdrawal
                                                    Amount</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    ₦{{ number_format($withdrawalData['grossAmount'], 2) }}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Platform
                                                    Fee</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #DC2626; text-align: right;">
                                                    -₦{{ number_format($withdrawalData['platformFee'], 2) }}</td>
                                            </tr>
                                            <tr>
                                                <td colspan="2"
                                                    style="border-top: 1px solid #e1e4e8; padding-top: 12px;"></td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Bank</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ $withdrawalData['bankName'] }}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Account
                                                    Number</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ $withdrawalData['accountNumber'] }}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Reference
                                                </td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-family: 'Courier New', monospace;">
                                                    {{ $withdrawalData['reference'] }}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Date</td>
                                                <td
                                                    style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">
                                                    {{ date('Y-m-d H:i:s') }}</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                Your withdrawal is being processed and should be credited to your account shortly.
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