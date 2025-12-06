import { Button } from './ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from './ui/dialog';
import { Input } from './ui/input';
import { Label } from './ui/label';

interface AddClientDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  clientName: string;
  setClientName: (name: string) => void;
  clientIp: string;
  setClientIp: (ip: string) => void;
  clientAllowedIps: string;
  setClientAllowedIps: (allowedIps: string) => void;
  onSubmit: () => void;
  isPending: boolean;
}

export function AddClientDialog({
  open,
  onOpenChange,
  clientName,
  setClientName,
  clientIp,
  setClientIp,
  clientAllowedIps,
  setClientAllowedIps,
  onSubmit,
  isPending,
}: AddClientDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700 sm:max-w-[425px] w-[calc(100%-2rem)]">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold text-slate-900 dark:text-white">
            Добавить нового клиента
          </DialogTitle>
          <DialogDescription className="text-slate-500 dark:text-slate-400">
            Укажите имя клиента. IP адрес будет назначен автоматически.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid gap-2">
            <Label htmlFor="name" className="text-slate-700 dark:text-slate-300">Имя клиента *</Label>
            <Input
              id="name"
              placeholder="client1"
              value={clientName}
              onChange={(e) => setClientName(e.target.value)}
              className="bg-white dark:bg-slate-700 border-slate-200 dark:border-slate-600 text-slate-900 dark:text-white"
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="ip" className="text-slate-700 dark:text-slate-300">IP адрес (опционально)</Label>
            <Input
              id="ip"
              placeholder="10.13.13.5"
              value={clientIp}
              onChange={(e) => setClientIp(e.target.value)}
              className="bg-white dark:bg-slate-700 border-slate-200 dark:border-slate-600 text-slate-900 dark:text-white"
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="allowedIps" className="text-slate-700 dark:text-slate-300">
              Дополнительные AllowedIPs (опционально)
            </Label>
            <Input
              id="allowedIps"
              placeholder="192.168.1.0/24"
              value={clientAllowedIps}
              onChange={(e) => setClientAllowedIps(e.target.value)}
              className="bg-white dark:bg-slate-700 border-slate-200 dark:border-slate-600 text-slate-900 dark:text-white"
            />
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Эти сети будут добавлены к глобальному AllowedIPs. Через запятую.
            </p>
          </div>
        </div>
        <DialogFooter className="flex-col sm:flex-row gap-2">
          <Button 
            variant="outline" 
            onClick={() => onOpenChange(false)} 
            className="w-full sm:w-auto dark:border-slate-600 dark:text-slate-300"
          >
            Отмена
          </Button>
          <Button 
            onClick={onSubmit} 
            disabled={isPending || !clientName.trim()} 
            className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700"
          >
            {isPending ? 'Создание...' : 'Создать'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
