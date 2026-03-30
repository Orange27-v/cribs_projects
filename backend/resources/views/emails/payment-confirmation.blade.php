<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment confirmation</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background-color: #f6f8fa; line-height: 1.6;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border: 1px solid #e1e4e8; border-radius: 6px;">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 32px 40px; border-bottom: 1px solid #e1e4e8;">
                            <img src="{{ asset('storage/logo/logo_light.png') }}" alt="Cribs Arena" style="height: 55px; display: block;" />
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 16px 0; font-size: 15px; color: #24292e;">Hi {{ $paymentData['userName'] }},</p>
                            
                            <p style="margin: 0 0 8px 0; font-size: 15px; color: #586069;">
                                Your payment has been processed successfully.
                            </p>
                            
                            <!-- Status Badge -->
                            <table cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td style="background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 3px; padding: 4px 12px;">
                                        <span style="font-size: 11px; font-weight: 600; color: #586069; text-transform: uppercase; letter-spacing: 0.5px;">Payment confirmed</span>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Amount Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td style="background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 6px; padding: 24px; text-align: center;">
                                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: #586069; margin-bottom: 8px;">Amount</div>
                                        <div style="font-size: 32px; font-weight: 600; color: #24292e;">₦{{ number_format($paymentData['amount'], 2) }}</div>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Payment Details -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0; background-color: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 6px;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <table width="100%" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Transaction ID</td>
                                                <td style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-family: 'Courier New', monospace;">{{ $paymentData['transactionId'] }}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Reference</td>
                                                <td style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-family: 'Courier New', monospace;">{{ $paymentData['reference'] }}</td>
                                            </tr>
                                            <tr>
                                                <td colspan="2" style="border-top: 1px solid #e1e4e8; padding-top: 12px;"></td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Payment method</td>
                                                <td style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">{{ $paymentData['paymentMethod'] ?? 'Card payment' }}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Date</td>
                                                <td style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">{{ $paymentData['paymentDate'] }}</td>
                                            </tr>
                                            <tr>
                                                <td colspan="2" style="border-top: 1px solid #e1e4e8; padding-top: 12px;"></td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Description</td>
                                                <td style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right;">{{ $paymentData['description'] }}</td>
                                            </tr>
                                            @if(isset($paymentData['bookingId']))
                                            <tr>
                                                <td style="padding: 8px 0; font-size: 13px; color: #586069;">Booking ID</td>
                                                <td style="padding: 8px 0; font-size: 13px; color: #24292e; text-align: right; font-weight: 500;">#{{ $paymentData['bookingId'] }}</td>
                                            </tr>
                                            @endif
                                        </table>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                This email serves as your receipt. Please keep it for your records.
                            </p>
                            
                            @if(isset($paymentData['bookingId']))
                            <p style="margin: 0 0 16px 0; font-size: 14px; color: #586069;">
                                Your inspection booking has been confirmed. You will receive a separate email with the booking details.
                            </p>
                            @endif
                            
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